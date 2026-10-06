#!/usr/bin/env bash
# check-skills.sh — Gate des skills par nature (B-03, FABR-06/09), miroir de check-agents.sh.
#
# Doctrine (Phase 43, spec fabrique §6) : chaque skill déclare sa NATURE en frontmatter —
# `vf-nature: referentiel | outil | procedure`, DÉFAUT « outil » quand la clé est absente
# (D-Q1, D-Q2 — aucun des SKILL.md du corpus (25 à l'armement, Phase 43 ; 26 au 2026-10-06) ne change
# de comportement à l'armement de ce gate). Une valeur PRÉSENTE mais hors de cet ensemble exact est REFUSÉE (rc 1) — jamais ramenée
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
# Contrat de clés (D-Q1, costly) : ces sept clés (`vf-nature`, `ecrit`, `vf-rubrique-juge`,
# `vf-gate-bloquant`, `vf-livrable-tiers`, `vf-couche-qualite`, `vf-invocation`) sont des CONVENTIONS VibeFlow —
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
#   check-skills.sh --callers-root=PATH    # + classe d'invocation (POCK-07) : classement exigé et arêtes
#                                          # d'appel lues sous PATH (commands/, agents/, */AGENT.md,
#                                          # */agents/) · incompatible avec --file · absent = inchangé
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
#
# --- Détection de dérive (D-Q1, D-Q5, FABR-07) — posée en 43-02, sur ce même gate ---------------
# Règle Q-PORTEE : décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26 (43-CONTEXT.md, bloc « Quatrième temps »).
# Portée : TOUT le corps du SKILL.md après fermeture du frontmatter (description: comprise, jamais lue), hors blocs de code
# délimités (bascule sur une ligne dont la partie non blanche commence par trois accents graves ou
# trois tildes ; une ligne à l'intérieur n'est ni détectée ni comptée, titre compris) ; recherche
# insensible à la casse. Titre = un à six dièses suivis d'un blanc ; prose = toute autre ligne du
# corps (gras, puces, tableaux et code en ligne compris). Portée dans le code par
# DERIVE_PROSE_MIN_DISTINCTS = 2 et DERIVE_TITRE_MIN = 1, chacune sur sa propre ligne. Avertissement
# « derive » déclenché SEULEMENT SI au moins deux des trois marqueurs DISTINCTS (gate bloquant,
# livrable remis à un tiers, couche de qualité) apparaissent en prose, OU si un seul marqueur
# apparaît dans un titre — jamais un refus (D-Q5), toujours un avertissement, même sous --strict.
# « Marqueur constaté » — définition UNIQUE lue par les DEUX sens de D-Q1 : un marqueur est
# constaté s'il apparaît dans au moins un titre, OU s'il apparaît en prose alors qu'au moins un
# second marqueur distinct apparaît aussi en prose (un mot isolé en prose n'est jamais un motif
# présent, dans aucun des deux sens). Sens corps -> frontmatter : marqueur constaté et déclaration
# absente ou false -> avertissement « derive ». Sens frontmatter -> corps : déclaration true et
# marqueur non constaté -> avertissement « ecart ». `lignes_de_portee(texte)` rend les lignes du
# corps dans la portée, chacune marquée titre ou prose ; `marqueurs_constates(lignes)` applique la
# règle UNE fois ; `detecter_derive` lit ce seul résultat pour les DEUX sens (appel unique dans
# check_file, toujours vers la liste des avertissements, JAMAIS vers les erreurs — cible
# MUT-DR1/MUT-DR2).
#
# MOTIFS_MARQUEURS (vocabulaire, décision de plan, costly — 43-RESEARCH.md Pitfall 2, aucun
# précédent codé) :
#   vf-gate-bloquant   -> \bgates?\b | \bbloquant(e|s|es)?\b
#   vf-livrable-tiers  -> \blivrables?\b | \bremis(e|es)?\s+(a|à|au|aux)\b | \bdestinataires?\b
#   vf-couche-qualite  -> \bjuges?\b | \brubriques?\b |
#     \bgrilles?\s+(de\s+)?(jug|notation|[ée]valuation|qualit) | checklist\s+qualit |
#     couche\s+(de\s+)?(jugement|qualit|d.audit) | quality\s+gate
#
# Écart nature <-> marqueurs (B-03, C-15, Tâche 2 de 43-02) : au moins un marqueur déclaré true et vf-nature différente de procedure (absente comptée comme outil) -> avertissement « ecart » citant B-03 et C-15 ; la nature n'est JAMAIS réécrite ni déduite (B-03 écarte la dérivation automatique). Appel unique dans check_file, vers la liste des avertissements (cible MUT-DR3).
#
# Mesure du corpus réel sous cette règle (2026-09-26, lecture seule, hors module doc-only, plugin/reference exclu) : 26 avertissements « derive » sur 11 SKILL.md/21 (0 « ecart » -- aucun marqueur encore déclaré true dans le corpus) ; liste complète au SUMMARY de 43-02 (CORPUS-DERIVE) — corpus laissé non corrigé (D-Q5, backlog séparé, .planning/BACKLOG.md entrée e36e6f2).
#
# --- Classe d'invocation (POCK-07, Phase 41.4) — posée en 41.4-01, sur ce même gate ----------------
# Champ VibeFlow `vf-invocation: user | model` (convention du dépôt, hors manifeste daté), jugé en
# tous les modes : valeur hors {user, model} (casse exacte) -> refus ; `user` exige le champ natif
# `disable-model-invocation: true` (insensible à la casse), `model` l'interdit (P414-D-01). Classer
# un skill est un acte HUMAIN : le gate refuse l'absence, il ne pose jamais la classe.
# Option `--callers-root=PATH` (racine d'arêtes : un dossier plugin/ source, ou .claude/ d'un lab) —
# sans elle, le comportement du hook de lab et des arbres par module (T4/T32) est INCHANGÉ. Sous
# l'option, en plus des contrôles ci-dessus :
#   - classement exigé : un SKILL.md sans vf-invocation est « non classe » (POCK-07) ;
#   - arêtes d'appel dérivées par MOT ENTIER (nom passé par re.escape, bornes [A-Za-z0-9_-]) sur
#     commands/*.md (commande), le champ skills: d'un agent (préchargement) et un agent qui cite le
#     nom ET peut appeler Skill (jeton Skill dans tools:, ou aucune ligne tools: = hérite de tout,
#     sauf disallowedTools: Skill) — jamais un nom de module en dur, agents lus : agents/*.md,
#     */AGENT.md, */agents/*.md. Une prose qui cite un skill depuis un agent SANS l'outil Skill
#     n'est PAS une arête machine ;
#   - un skill `user` appelé par l'une de ces arêtes est refusé, l'appelant nommé (P414-D-02) ; un
#     `user` dont le corps cite un autre `user` est refusé (P414-D-01) ; un `user` qui cite un
#     `model` est légitime ;
#   - équivalent Codex (P414-D-03) : un `user` NICHÉ (skills/<nom>/SKILL.md) exige
#     agents/openai.yaml, fichier régulier dont la valeur RÉSOLUE de `policy.allow_implicit_invocation`
#     (enfant direct de l'unique clé `policy:` de niveau 0, commentaire de fin de ligne exclu, ni
#     tabulation d'indentation ni forme en flux) vaut `false` — lecteur `valeur_implicite_codex` ;
#     un `user` NON niché (module Type 1, SKILL.md copié seul par l'installeur) est une DETTE
#     signalée par avertissement, jamais un refus ;
#   - ligne d'information « sans appelant machine » (jamais comptée en avertissement) : le gate LISTE
#     les skills sans aucune arête, candidats user-invoked seulement si effet de bord lourd — le
#     jugement humain n'est pas calculé (P414-D-01).
# TROIS ISSUES de ce régime : 0 = conforme (dettes Type 1 et information permises) · 1 = skill non
# classé, valeur invalide, user appelé, user -> user, ou agents/openai.yaml absent ou non conforme ·
# 3 = INDETERMINE : racine d'arêtes absente ou sans aucun fichier appelant (jeton ARETES-ABSENTES) —
# jamais un vert à vide ; sous --hook, 3 devient 0 à la frontière du shell comme ailleurs.

set -uo pipefail

SKILLS_DIR=".claude/skills"
STRICT=false
HOOK_MODE=false
ALLOW_EMPTY=false
SINGLE_FILE=""
THIRD_PARTY_PREFIXES="gsd-"
CALLERS_ROOT=""

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
    --callers-root=*)
      v="${arg#*=}"
      if [ -z "$v" ]; then
        echo "[check-skills] ✗ --callers-root vide — un chemin est requis" >&2
        exit 1
      fi
      CALLERS_ROOT="$v"
      ;;
    --callers-root)
      echo "[check-skills] ✗ --callers-root exige la forme --callers-root=PATH (jamais ignoré en silence)" >&2
      exit 1
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
if [ -n "$CALLERS_ROOT" ] && [ -n "$SINGLE_FILE" ]; then
  echo "[check-skills] ✗ --callers-root incompatible avec --file — les aretes se calculent sur un arbre, jamais sur un fichier isole" >&2
  exit 1
fi

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
VF_CALLERS_ROOT="$CALLERS_ROOT" \
"$PYBIN" - <<'PY_CHECK_SKILLS_EOF'
import glob, json, os, re, sys
from datetime import date

manifest_path = os.environ["VF_MANIFEST"]
skills_dir = os.environ["VF_SKILLS_DIR"]
strict = os.environ["VF_STRICT"] == "true"
hook = os.environ["VF_HOOK"] == "true"
allow_empty = os.environ["VF_ALLOW_EMPTY"] == "true"
single = os.environ["VF_SINGLE"]
callers_root = os.environ.get("VF_CALLERS_ROOT", "")
third_party_prefixes = [p for p in os.environ.get("VF_THIRD_PARTY_PREFIXES", "").split(":") if p]

# Conventions VibeFlow en dur (D-Q1) — jamais dans le manifeste, jamais sujettes a la peremption
# d'une doc Anthropic externe (meme frontiere que D-01, Phase 42) :
VIBEFLOW_SKILL_FIELDS = {"vf-nature", "ecrit", "vf-rubrique-juge", "vf-gate-bloquant",
                         "vf-livrable-tiers", "vf-couche-qualite", "vf-invocation"}
NATURES = {"referentiel", "outil", "procedure"}
CLASSES_INVOCATION = {"user", "model"}
MARQUEURS = ("vf-gate-bloquant", "vf-livrable-tiers", "vf-couche-qualite")

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
skills_juges = []  # (chemin relatif, chemin reel, frontmatter, texte) de chaque skill juge (POCK-07)

def sans_commentaire_yaml(val):
    """Valeur YAML d'un scalaire ou d'une liste en ligne : le commentaire de fin de ligne
    (`#` precede d'un blanc ou en tete, HORS guillemets) est exclu. Un guillemet n'ouvre une
    chaine qu'en debut de jeton (apres blanc, `[` ou `,`) : une apostrophe de mot ne masque rien."""
    quote = None
    for i, c in enumerate(val):
        if quote:
            if c == quote:
                quote = None
        elif c in (chr(34), chr(39)) and (i == 0 or val[i - 1] in " \t[,"):
            quote = c
        elif c == "#" and (i == 0 or val[i - 1] in " \t"):
            return val[:i].rstrip()
    return val

def parse_frontmatter(text, commentaires=False):
    """Meme tokenizer YAML-tolerant (scalaire/liste/continuation) que check-agents.sh — recopie
    verbatim, aucune divergence de comportement entre les deux gates sur ce point. Option
    `commentaires` (M-02, N-13) : la valeur lue est la valeur YAML, le commentaire de fin de ligne
    exclu, quelle que soit la forme (scalaire, liste en ligne ; la liste de bloc le fait deja) —
    jouee par check_file (UNE seule lecture du frontmatter d'un SKILL.md, controles ET aretes) et
    par decouvrir_appelants."""
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
            if commentaires:
                val = sans_commentaire_yaml(val)
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

# V5 (43-RESEARCH.md § Security Domain) : enumeration stricte, refus explicite, jamais un defaut
# silencieux sur une entree malformee. Charset Unicode-aware (\w admet les lettres accentuees) ;
# espace, ';', '$', '(', ')', '|', '&', backtick et tout caractere de controle sont refuses.
_ECRIT_ENTRY_RE = re.compile(r"^[\w./<>{}*-]+$", re.UNICODE)

def entree_chemin_valide(v):
    if not isinstance(v, str):
        return False
    v = v.strip()
    if v == "":
        return False
    if v.startswith("/") or v.startswith("~"):
        return False
    if ".." in v.split("/"):
        return False
    return bool(_ECRIT_ENTRY_RE.fullmatch(v))

def valider_ecrit(rel, valeur):
    """ecrit: (scalaire ou liste) — chaque entree non vide doit etre un chemin relatif propre.
    Une entree individuelle vide au sein d'une liste est tolere comme absente (invariant_procedure
    la compte deja) ; seule une entree NON VIDE malformee est un refus."""
    if is_absent_value(valeur):
        return []
    entries = valeur if isinstance(valeur, list) else [valeur]
    msgs = []
    for e in entries:
        if isinstance(e, str) and e.strip() == "":
            continue
        if not entree_chemin_valide(e):
            msgs.append(f"{rel} : ecrit: entree malformee {esc(e)} — chemin relatif attendu, sans '..', sans '/' ni '~' initial (FABR-06)")
    return msgs

def valider_rubrique_juge(rel, valeur):
    """vf-rubrique-juge : SCALAIRE seulement (une liste est refusee), meme regle de forme
    qu'une entree de ecrit:. Valeur vide/absente n'est jamais un refus ICI (invariant_procedure
    la compte deja comme manquante pour FABR-06)."""
    if is_absent_value(valeur):
        return []
    if isinstance(valeur, list):
        return [f"{rel} : vf-rubrique-juge invalide {esc(valeur)} — scalaire attendu, pas une liste (FABR-06)"]
    if not entree_chemin_valide(valeur):
        return [f"{rel} : vf-rubrique-juge invalide {esc(valeur)} — chemin relatif ou nom d'agent attendu, sans '..', sans '/' ni '~' initial (FABR-06)"]
    return []

def valider_marqueurs(rel, fm):
    """Les trois marqueurs de B-03/C-15 sont optionnels ; presents, ils n'acceptent que
    true|false (minuscules) — D-Q1."""
    msgs = []
    for cle in MARQUEURS:
        if cle not in fm:
            continue
        val = fm[cle]
        if val not in ("true", "false"):
            msgs.append(f"{rel} : {cle} invalide {esc(val)} — attendu true|false (D-Q1)")
    return msgs

def skill_display_name(text):
    fm = parse_frontmatter(text)
    if fm and isinstance(fm.get("name"), str) and fm.get("name"):
        return fm["name"]
    return ""

def skills_non_classes(juges):
    """POCK-07, P414-D-01 : un skill sans cle vf-invocation n'est pas classe. Joue SOUS
    --callers-root seulement (le hook de lab, arbre par module, reste inchange). Une cle PRESENTE
    mais vide ou invalide n'est pas « non classe » : valider_invocation la refuse deja."""
    msgs = []
    for rel, _chemin, fm, _texte in juges:
        if "vf-invocation" not in fm:
            msgs.append(f"{rel} : non classe — vf-invocation absent (POCK-07, P414-D-01) ; attendu user ou model")
    return msgs

def lister_md(dossier):
    """Fichiers .md reguliers DIRECTEMENT sous dossier — aucun lien symbolique (fichier) retenu,
    ordre stable. Dossier absent ou illisible : liste vide."""
    try:
        noms = sorted(os.listdir(dossier))
    except OSError:
        return []
    out = []
    for n in noms:
        p = os.path.join(dossier, n)
        if n.endswith('.md') and os.path.isfile(p) and not os.path.islink(p):
            out.append(p)
    return out

def decouvrir_appelants(racine):
    """POCK-07 : fichiers qui PEUVENT appeler un skill, sous la racine d'aretes —
    {racine}/commands/*.md (commande), {racine}/agents/*.md, {racine}/*/AGENT.md et
    {racine}/*/agents/*.md (agent). Memes exclusions que la decouverte des skills : dossiers caches
    et *-references, aucun lien symbolique suivi. Rend une liste de dicts
    {rel, kind, fm, text} ; racine absente ou sans aucun de ces fichiers : liste vide (l'appelant
    en fait un INDETERMINE, jamais un vert a vide). Aucun nom de module en dur."""
    if not os.path.isdir(racine):
        return []
    cibles = [("commande", p) for p in lister_md(os.path.join(racine, "commands"))]
    cibles += [("agent", p) for p in lister_md(os.path.join(racine, "agents"))]
    try:
        sous_dossiers = sorted(os.listdir(racine))
    except OSError:
        sous_dossiers = []
    for d in sous_dossiers:
        if d.startswith('.') or d.endswith('-references'):
            continue
        dp = os.path.join(racine, d)
        if os.path.islink(dp) or not os.path.isdir(dp):
            continue
        ag = os.path.join(dp, "AGENT.md")
        if os.path.isfile(ag) and not os.path.islink(ag):
            cibles.append(("agent", ag))
        cibles += [("agent", p) for p in lister_md(os.path.join(dp, "agents"))]
    appelants = []
    for kind, chemin in cibles:
        rel = os.path.relpath(chemin, racine).replace(os.sep, "/")
        try:
            texte = open(chemin, encoding="utf-8-sig").read()
        except OSError as e:
            errors.append(f"{rel} : appelant illisible ({e}) — aretes non calculables")
            continue
        fm = parse_frontmatter(texte, commentaires=True) if kind == "agent" else None
        for cle in (("skills", "tools", "disallowedTools", "disallowed-tools") if fm else ()):
            v = fm.get(cle)
            if isinstance(v, str) and v.startswith("["):
                errors.append(f"{rel} : champ {cle} non interpretable (liste en ligne non refermee) — aretes non calculables")
        appelants.append({"rel": rel, "kind": kind, "fm": fm if fm is not None else {}, "text": texte})
    return appelants

# --- Detection de derive (D-Q1, D-Q5, FABR-07) -- regle Q-PORTEE complete dans l'en-tete du script
# (decision deleguee par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26)
DERIVE_PROSE_MIN_DISTINCTS = 2
DERIVE_TITRE_MIN = 1

MOTIFS_MARQUEURS = {
    "vf-gate-bloquant": [r"\bgates?\b", r"\bbloquant(e|s|es)?\b"],
    "vf-livrable-tiers": [r"\blivrables?\b", r"\bremis(e|es)?\s+(a|à|au|aux)\b", r"\bdestinataires?\b"],
    "vf-couche-qualite": [
        r"\bjuges?\b",
        r"\brubriques?\b",
        r"\bgrilles?\s+(de\s+)?(jug|notation|[ée]valuation|qualit)",
        r"checklist\s+qualit",
        r"couche\s+(de\s+)?(jugement|qualit|d.audit)",
        r"quality\s+gate",
    ],
}
_MOTIFS_COMPILES = {k: [re.compile(p, re.IGNORECASE | re.UNICODE) for p in v] for k, v in MOTIFS_MARQUEURS.items()}


def lignes_de_portee(texte):
    """Rend la liste des lignes du CORPS (apres fermeture du frontmatter) dans la portee de la
    regle Q-PORTEE, chacune marquee ('titre'|'prose', ligne_originale) -- hors blocs de code
    delimites (bascule sur une ligne dont la partie non blanche commence par trois accents graves
    ou trois tildes ; une ligne a l'interieur n'est ni detectee ni comptee, titre compris).
    Resultat identique que la bascule soit lue en tout debut de ligne ou apres une indentation
    (comparaison faite apres lstrip)."""
    lines = texte.split("\n")
    start = 0
    if lines and lines[0].strip() == "---":
        i = 1
        while i < len(lines) and lines[i].strip() != "---":
            i += 1
        start = i + 1 if i < len(lines) else len(lines)
    out = []
    in_code = False
    fence = None
    for line in lines[start:]:
        stripped = line.lstrip()
        prefix = stripped[:3]
        if not in_code and prefix in ("```", "~~~"):
            in_code = True
            fence = prefix
            continue
        if in_code:
            if prefix == fence:
                in_code = False
                fence = None
            continue
        if re.match(r"^#{1,6}\s", line):
            out.append(("titre", line))
        else:
            out.append(("prose", line))
    return out


def marqueurs_constates(lignes):
    """Applique la regle Q-PORTEE UNE seule fois (D-Q1) : un marqueur trouve dans au moins un
    titre (DERIVE_TITRE_MIN) est TOUJOURS constate ; un marqueur trouve en prose n'est constate
    que si le nombre de marqueurs DISTINCTS trouves en prose atteint DERIVE_PROSE_MIN_DISTINCTS
    (deux occurrences du meme marqueur, ou deux mots du vocabulaire d'un meme marqueur, ne comptent
    que pour un). Rend, par marqueur constate, un tuple (emplacement, ligne_de_preuve) -- premier
    titre, a defaut premiere ligne de prose."""
    titre_trouves = {}
    prose_trouves = {}
    for typ, line in lignes:
        cible = titre_trouves if typ == "titre" else prose_trouves
        for cle, pats in _MOTIFS_COMPILES.items():
            if cle in cible:
                continue
            for pat in pats:
                if pat.search(line):
                    cible[cle] = line.strip()
                    break
    constates = {}
    if len(titre_trouves) >= DERIVE_TITRE_MIN:
        for cle, preuve in titre_trouves.items():
            constates[cle] = ("titre", preuve)
    if len(prose_trouves) >= DERIVE_PROSE_MIN_DISTINCTS:
        for cle, preuve in prose_trouves.items():
            if cle not in constates:
                constates[cle] = ("prose", preuve)
    return constates


def detecter_derive(rel, fm, lignes):
    """FABR-07, D-Q1, D-Q5 : lit marqueurs_constates() UNE fois pour les DEUX sens (patron
    invariant_i1 de check-agents.sh, jamais un message fusionne) : marqueur constate et
    declaration absente ou false -> avertissement "derive" ; declaration true et marqueur non
    constate -> avertissement "ecart". Toujours des warnings, jamais des errors (D-Q5) -- l'appel
    unique est cible par MUT-DR1 (neutralisation) et MUT-DR2 (promotion en errors)."""
    constates = marqueurs_constates(lignes)
    msgs = []
    for cle in MARQUEURS:
        declare_true = fm.get(cle) == "true"
        if cle in constates:
            emplacement, preuve = constates[cle]
            if not declare_true:
                msgs.append(
                    f"{rel} : derive — motif de {cle} en {emplacement} dans la ligne "
                    f"« {esc(preuve)} » sans {cle}: true declare (D-Q1)"
                )
        elif declare_true:
            msgs.append(
                f"{rel} : ecart — {cle}: true declare sans motif de {cle} dans le corps "
                f"(un titre, ou au moins deux marqueurs distincts en prose) (D-Q1)"
            )
    return msgs


def ecart_nature_marqueurs(rel, fm):
    """B-03, C-15 (Tache 2, 43-02) : au moins un marqueur declare true et vf-nature differente de
    procedure (absente comptee comme outil) -> avertissement "ecart" -- la nature n'est JAMAIS
    reecrite ni deduite (B-03 ecarte la derivation automatique)."""
    declares = [cle for cle in MARQUEURS if fm.get(cle) == "true"]
    if not declares:
        return []
    nature = fm.get("vf-nature", "outil")
    if not isinstance(nature, str) or nature == "":
        nature = "outil"
    if nature == "procedure":
        return []
    liste = ", ".join(declares)
    return [
        f"{rel} : ecart — marqueur(s) {liste} declare(s) mais vf-nature: {nature} — au moins un "
        f"marqueur designe une procedure (B-03, C-15) ; la nature reste declaree, jamais deduite"
    ]

def est_vrai(v):
    """Valeur YAML « true » d'un champ NATIF (disable-model-invocation) : insensible a la casse,
    comme le lit le harnais — `True` desactive aussi l'invocation par le modele."""
    return isinstance(v, str) and v.strip().lower() == "true"

def valider_invocation(rel, fm):
    """POCK-07, P414-D-01 : vf-invocation PRESENT doit valoir exactement user ou model (casse
    exacte, jamais ramene a un defaut) ET etre coherent avec le champ natif : `user` exige
    disable-model-invocation: true, `model` l'interdit. Joue dans TOUS les modes — la valeur est
    un fait du fichier, pas une arete. Cle ABSENTE : jamais une erreur ICI (skills_non_classes la
    juge, sous --callers-root seulement)."""
    if "vf-invocation" not in fm:
        return []
    val = fm["vf-invocation"]
    if not isinstance(val, str) or val not in CLASSES_INVOCATION:
        return [f"{rel} : vf-invocation invalide — {esc(val)} (attendu user ou model, POCK-07)"]
    desactive = est_vrai(fm.get("disable-model-invocation"))
    if val == "user" and not desactive:
        return [f"{rel} : vf-invocation: user sans disable-model-invocation: true (P414-D-01)"]
    if val == "model" and desactive:
        return [f"{rel} : vf-invocation: model avec disable-model-invocation: true (P414-D-01)"]
    return []

def mot_entier_re(nom):
    """Regex de mot ENTIER pour un nom de skill (T-41.4-01) : le nom est passe par re.escape (un
    point reste un point litteral), bornes = aucun caractere [A-Za-z0-9_-] de part et d'autre
    (« vf-dev » n'apparie pas « vf-dev-manager »)."""
    return re.compile(r"(?<![A-Za-z0-9_-])" + re.escape(nom) + r"(?![A-Za-z0-9_-])")

def jetons_champ(v):
    """Jetons d'un champ de frontmatter : liste (bloc ou en ligne) ou scalaire separe par des
    virgules ; vides ecartes."""
    if isinstance(v, list):
        items = v
    elif isinstance(v, str):
        items = v.split(",")
    else:
        return []
    out = []
    for x in items:
        x = str(x).strip().strip(chr(34)).strip(chr(39))
        if x:
            out.append(x)
    return out

def agent_outille_skill(fm):
    """Un agent peut appeler un skill s'il porte l'outil Skill (jeton `Skill` ou `Skill(...)` dans
    tools:) OU n'a aucune ligne tools: (il herite de tout) — sauf si disallowedTools porte le jeton
    Skill. Un agent de tools: Read, Bash qui cite un skill en prose n'a AUCUNE arete machine."""
    tools = jetons_champ(fm.get("tools"))
    if not tools:
        outille = True
    else:
        outille = any(t == "Skill" or t.startswith("Skill(") for t in tools)
    interdits = jetons_champ(fm.get("disallowedTools", fm.get("disallowed-tools")))
    if "Skill" in interdits:
        return False
    return outille

def identite_skill(chemin, fm):
    """Identite d'un skill dans le calcul des aretes (M-01) : le `name:` declare, a defaut le nom
    de son dossier (c'est ainsi que le harnais le nomme). None si ni l'un ni l'autre n'est
    exploitable : le skill est alors REFUSE par controler_aretes, jamais exempte en silence."""
    nom = fm.get("name")
    if isinstance(nom, str) and nom:
        return nom
    if "name" in fm:
        return None  # name present mais vide ou non scalaire : ne pas deviner
    dossier = os.path.basename(os.path.dirname(os.path.abspath(chemin)))
    return dossier or None

def aretes_par_skill(juges, appelants):
    """Aretes d'appel DERIVEES (jamais un nom de module en dur) : rel du skill -> liste de
    (famille, rel de l'appelant). Familles : commande (fichier commands/*.md qui contient le nom,
    mot entier), prechargement (nom dans le champ skills: d'un agent), agent (agent qui contient
    le nom ET dont l'outillage permet Skill)."""
    aretes = {}
    for rel, chemin, fm, _texte in juges:
        liste = []
        aretes[rel] = liste
        nom = identite_skill(chemin, fm)
        if not nom:
            continue
        motif = mot_entier_re(nom)
        for ap in appelants:
            if ap["kind"] == "commande":
                if motif.search(ap["text"]):
                    liste.append(("commande", ap["rel"]))
                continue
            if nom in jetons_champ(ap["fm"].get("skills")):
                liste.append(("prechargement", ap["rel"]))
                continue
            if not motif.search(ap["text"]):
                continue
            if not agent_outille_skill(ap["fm"]):
                continue
            liste.append(("agent", ap["rel"]))
    return aretes

def corps_sans_frontmatter(texte):
    lignes = texte.split("\n")
    i = 1
    while i < len(lignes) and lignes[i].strip() != "---":
        i += 1
    return "\n".join(lignes[i + 1:])

def controler_aretes(juges, appelants):
    """POCK-07, P414-D-01/D-02 : un skill `user` appele par une commande, un prechargement ou un
    agent outille Skill est refuse (une erreur par appelant, qui le nomme) ; un `user` dont le
    corps cite un AUTRE `user` est refuse. Un user qui cite un model est legitime."""
    aretes = aretes_par_skill(juges, appelants)
    users = {}
    msgs = []
    for rel, chemin, fm, _texte in juges:
        nom = identite_skill(chemin, fm)
        if not nom:
            msgs.append(f"{rel} : identite du skill indeterminable (name: vide ou non scalaire) — aretes non calculables, refuse (M-01)")
        elif fm.get("vf-invocation") == "user":
            users[nom] = rel
    for rel, chemin, fm, texte in juges:
        if fm.get("vf-invocation") != "user":
            continue
        for famille, ap_rel in aretes.get(rel, []):
            msgs.append(f"{rel} : user-invoked appele par {ap_rel} ({famille}) — refuse (P414-D-02)")
        corps = corps_sans_frontmatter(texte)
        for nom_cible in sorted(users):
            if nom_cible == identite_skill(chemin, fm):
                continue
            if mot_entier_re(nom_cible).search(corps):
                msgs.append(f"{rel} : user-invoked cite le user-invoked {esc(nom_cible)} — refuse (P414-D-01)")
    return msgs

def est_imbrique(chemin):
    """Skill NICHE (Type 2) : le dossier parent de son dossier se nomme `skills`
    (skills/<nom>/SKILL.md). Un SKILL.md sous un dossier de module (Type 1) ne l'est pas."""
    dossier_skill = os.path.dirname(os.path.abspath(chemin))
    return os.path.basename(os.path.dirname(dossier_skill)) == "skills"

def valeur_implicite_codex(texte):
    """M-03 : valeur RESOLUE et unique de policy.allow_implicit_invocation dans un openai.yaml.
    Lecteur YAML minimal par indentation (aucune dependance) : la cle `policy:` au niveau 0 (une
    seule), la cle `allow_implicit_invocation` parmi SES enfants directs (une seule), valeur
    booleenne `false` (commentaire de fin de ligne exclu). Rend (conforme, raison) ; toute forme
    non interpretable (flux `{...}`, doublon, mauvais parent, valeur non booleenne) = refus."""
    lignes = []
    for brut in texte.split("\n"):
        l = brut.rstrip("\r")
        if not l.strip() or l.lstrip().startswith("#"):
            continue
        if "\t" in l[:len(l) - len(l.lstrip())]:
            return False, "tabulation en indentation, non interpretable"
        lignes.append((len(l) - len(l.lstrip(" ")), l.strip()))
    policies = [i for i, (ind, c) in enumerate(lignes) if ind == 0 and re.match(r"^policy\s*:", c)]
    if len(policies) != 1:
        return False, "cle policy: absente ou en double"
    debut = policies[0]
    reste = sans_commentaire_yaml(lignes[debut][1].split(":", 1)[1].strip())
    if reste:
        return False, "policy: en forme de flux ou de scalaire, non interpretable"
    enfants, indent_enfant = [], None
    for ind, c in lignes[debut + 1:]:
        if ind == 0:
            break
        if indent_enfant is None:
            indent_enfant = ind
        if ind == indent_enfant:
            enfants.append(c)
    vals = []
    for c in enfants:
        m = re.match(r"^allow_implicit_invocation\s*:(.*)$", c)
        if m:
            vals.append(sans_commentaire_yaml(m.group(1).strip()).strip(chr(34) + chr(39)))
    if len(vals) != 1:
        return False, "allow_implicit_invocation absent ou en double sous policy:"
    if vals[0].lower() != "false":
        return False, f"valeur resolue {vals[0]!r} (attendu false)"
    return True, ""

def controler_codex(juges):
    """P414-D-03 : un skill `user` NICHE exige {dossier}/agents/openai.yaml — fichier regulier
    (jamais un lien) dont la valeur RESOLUE de policy.allow_implicit_invocation vaut `false`
    (lecteur valeur_implicite_codex : cle policy: unique au niveau 0, enfant direct unique,
    commentaire exclu — equivalent Codex de disable-model-invocation)."""
    msgs = []
    for rel, chemin, fm, _texte in juges:
        if fm.get("vf-invocation") != "user" or not est_imbrique(chemin):
            continue
        oy = os.path.join(os.path.dirname(chemin), "agents", "openai.yaml")
        conforme, raison = False, "fichier absent, illisible ou lien symbolique"
        if os.path.isfile(oy) and not os.path.islink(oy):
            try:
                with open(oy, encoding="utf-8-sig") as fh:
                    conforme, raison = valeur_implicite_codex(fh.read())
            except OSError:
                conforme, raison = False, "fichier illisible"
        if not conforme:
            msgs.append(f"{rel} : user-invoked niche sans agents/openai.yaml (policy.allow_implicit_invocation: false) — P414-D-03 [{raison}]")
    return msgs

def dette_type1(juges):
    """P414-D-03 : un skill `user` NON niche (module Type 1, copie du SKILL.md seul par
    l'installeur) ne peut pas transporter l'equivalent Codex — avertissement de dette, jamais un
    refus (le poser dans plugin/<mod>/agents/ le ferait installer comme AGENT)."""
    return [f"{rel} : dette Type 1 (P414-D-03) — equivalent Codex non transporte par l'installeur (copie du SKILL.md seul)"
            for rel, chemin, fm, _texte in juges
            if fm.get("vf-invocation") == "user" and not est_imbrique(chemin)]

def sans_appelant(juges, appelants):
    """Noms des skills non user sans aucune arete machine (commande, prechargement, agent outille
    Skill) — information pour le jugement humain (P414-D-01) ; le gate LISTE, il ne pose rien."""
    aretes = aretes_par_skill(juges, appelants)
    noms = set()
    for rel, chemin, fm, _texte in juges:
        nom = identite_skill(chemin, fm)
        if fm.get("vf-invocation") != "user" and nom and not aretes.get(rel):
            noms.add(nom)
    return sorted(noms)

def check_file(rel, text):
    """Juge un SKILL.md ; rend SON frontmatter (None si illisible). UNE seule lecture (N-13) : la
    valeur d'un champ est la valeur YAML (commentaire de fin de ligne exclu) pour TOUS les controles
    ET pour le calcul des aretes — `vf-invocation: model # classe` ne rougit plus a tort."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        errors.append(f"{rel} : frontmatter absent (--- ... ---) — aucun verdict possible")
        return None
    fm = parse_frontmatter(text, commentaires=True)
    if fm is None:
        errors.append(f"{rel} : frontmatter jamais referme (--- ... ---) — aucun verdict possible")
        return None
    errors.extend(valider_nature(rel, fm))
    errors.extend(invariant_procedure(rel, fm))
    errors.extend(valider_ecrit(rel, fm.get("ecrit")))
    errors.extend(valider_rubrique_juge(rel, fm.get("vf-rubrique-juge")))
    errors.extend(valider_marqueurs(rel, fm))
    errors.extend(valider_invocation(rel, fm))
    warnings.extend(detecter_derive(rel, fm, lignes_de_portee(text)))
    warnings.extend(ecart_nature_marqueurs(rel, fm))
    for k in fm:
        if k not in KNOWN:
            warnings.append(f"{rel} : champ inconnu — {k} (typo ? verifier la doc)")
    return fm

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
        fm_juge = check_file(os.path.relpath(f, skills_dir), text)
        linted_paths.append(f)
        if fm_juge is not None:
            skills_juges.append((os.path.relpath(f, skills_dir), f, fm_juge, text))

# --- Classe d'invocation (POCK-07, Phase 41.4) : jouee SEULEMENT sous --callers-root -------------
# Le hook de lab et les arbres par module (T4/T32) n'ont pas de racine d'aretes : leur comportement
# est inchange. Racine absente ou sans aucun fichier appelant = INDETERMINE (rc 3) — jamais un vert
# a vide, la conformite d'un skill « user » ne se juge pas sans ses aretes (T-41.4-02).
liste_sans_appelant = None  # None hors --callers-root : la ligne d'information n'est pas imprimee
if callers_root:
    appelants_trouves = decouvrir_appelants(callers_root)
    if not appelants_trouves:
        if not hook:
            cause = "racine absente" if not os.path.isdir(callers_root) else "aucun fichier appelant (commands/*.md, agents/*.md, */AGENT.md, */agents/*.md)"
            print(f"[check-skills] ✗ INDETERMINE : {callers_root} — ARETES-ABSENTES, aucune arete calculable ({cause}) — aucun verdict rendu")
        sys.exit(3)
    errors.extend(skills_non_classes(skills_juges))
    errors.extend(controler_aretes(skills_juges, appelants_trouves))
    errors.extend(controler_codex(skills_juges))
    warnings.extend(dette_type1(skills_juges))
    liste_sans_appelant = sans_appelant(skills_juges, appelants_trouves)

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
if liste_sans_appelant is not None:
    # Information, JAMAIS comptee en avertissement : le gate liste, il ne pose rien (P414-D-01).
    noms_sans_appelant = ", ".join(esc(n) for n in liste_sans_appelant) if liste_sans_appelant else "(aucun)"
    print(f"[check-skills] sans appelant machine (commande, prechargement, agent outille Skill) : {noms_sans_appelant} — candidats user-invoked seulement si effet de bord lourd (jugement humain, P414-D-01)")
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
