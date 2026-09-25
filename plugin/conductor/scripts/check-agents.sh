#!/usr/bin/env bash
# check-agents.sh — Lint machine de la conformité NATIVE des agents Claude Code (ADR-044).
# Ce qui passait silencieusement : agents sans description (jamais auto-routés), sans model,
# sans memory, skills déclarés jamais créés (hallucination), champs inconnus (typos), et —
# depuis la Phase 16 — des allowlists Agent(...) opaques : noms d'agents inventés, parenthèse
# non fermée, outils hors du set connu passaient tous --strict en vert.
#
# Portée réelle du lint Agent(...) (doc sub-agents, vérifiée 2026-07-27, citation verbatim) :
#   « The Agent(agent_type) allowlist syntax applies only to an agent running as the main
#   thread with `claude --agent`. In a subagent definition, listing Agent in tools lets that
#   subagent spawn subagents of its own [...], but any type list inside the parentheses is
#   ignored. » — https://code.claude.com/docs/en/sub-agents
# Concrètement : sur un agent posé sous .claude/agents/ (donc dispatché en SOUS-agent, jamais
# incarné en thread principal), le runtime IGNORE la liste de noms entre parenthèses — seul le
# fait que `Agent`/`Task` soit présent dans `tools:` compte pour le runtime. L'allowlist
# `Agent(x, y)` n'est donc PAS un bac à sable runtime pour ces agents : c'est un CONTRAT
# documenté, désormais enforcé PAR CE LINT (et seulement par lui). Elle redevient une vraie
# restriction runtime uniquement pour un agent incarné en thread principal (`claude --agent`).
#
# Référentiel : manifeste daté check-agents-manifest.json (même dossier que ce script) — six
# listes, verifie_le + source par liste, valide_jours porté par le manifeste ; absent, illisible
# ou invalide → MANIFESTE-ILLISIBLE, rc 1 (0 sous --hook) ; chargé seulement s'il y a au moins un
# agent à juger ; la garde d'écriture traite cet incident comme une panne du contrôleur.
# + charte VibeFlow (souveraineté : model explicite + memory explicite + skills câblés).
#
# Fraîcheur du manifeste (Phase 42, FABR-02, D-02/D-04/D-05) : chaque liste porte son échéance
# (verifie_le + valide_jours, lus dans le manifeste, jamais en dur ici). Une liste est PÉRIMÉE
# quand son verifie_le a plus de valide_jours jours, OU quand il est postérieur à aujourd'hui
# (DATE-FUTURE, non vérifiable). Effet (D-04, D-05) : l'INDÉTERMINÉ (exit 3, MANIFESTE-PERIME)
# n'est rendu QUE sous --manifest-freshness=strict — c'est la CI du dépôt qui l'active à ses
# quatre appels de check-agents.sh, seul endroit avec la légitimité de rafraîchir le manifeste.
# Partout ailleurs (hook SessionStart, garde d'écriture, CLI sans l'option), un manifeste périmé
# ne produit qu'un AVERTISSEMENT — jamais un refus — et rétrograde en avertissement les erreurs
# « outil hors du set connu » et « nom d'agent non résolu » (suffixe [MANIFESTE-PERIME —
# retrograde en avertissement, D-05]) ; « champ inconnu » reste un avertissement inchangé ;
# model/memory/effort/permissionMode restent bloquants dans tous les cas (Pitfall 3 : un modèle
# inventé reste inventé, indépendamment de la fraîcheur de la doc). Le seul geste qui lève le
# rouge est de rafraîchir check-agents-manifest.json (relire chaque source, comparer, re-dater) —
# conséquence connue : la CI rougit à ses quatre appels à l'échéance, et T20 de
# test-dev-orchestrator.sh (qui compte les avertissements d'un AGENT.md) en compte un de plus.
#
# Usage:
#   check-agents.sh                     # lint .claude/agents/*.md · exit 1 si non conforme
#   check-agents.sh --strict            # GATE init : + les skills déclarés doivent EXISTER
#   check-agents.sh --hook              # SessionStart : compact, exit 0 toujours
#   check-agents.sh --file <agent.md>   # un seul fichier (utilisé par guard-agent-write)
#   check-agents.sh --agents-dir=PATH   # défaut .claude/agents
#   check-agents.sh --allow-empty       # avec --strict : tolère une cible vide (sinon exit 3)
#   check-agents.sh --third-party-prefix=PFX     # répétable, défaut gsd- (accumule AU-DESSUS
#                                                 # du défaut ; --no-third-party-prefix avant pour repartir de zéro)
#   check-agents.sh --no-third-party-prefix      # vide la liste des préfixes tiers
#   check-agents.sh --resolve-agents=lenient|strict  # défaut lenient (monde ouvert) — toute
#                                                 # autre valeur est REJETÉE (exit 1, jamais un skip muet)
#   check-agents.sh --agent-registry-dir=PATH    # répétable, dirs de résolution supplémentaires
#   check-agents.sh --manifest-freshness=lenient|strict  # défaut lenient — strict seul rend
#                                                 # INDETERMINE (exit 3) sur manifeste perime,
#                                                 # reserve a la CI du depot (D-04) ; toute autre
#                                                 # valeur est REJETEE (exit 1, jamais un skip muet)
#
# BLOQUANT : frontmatter absent · name absent/invalide · description absente ·
#   model absent ou hors du set du manifeste daté (+ claude-<id>) · memory absente ou hors
#   {user,project,local} · effort absent ou hors du set du manifeste daté ·
#   permissionMode/isolation/background/maxTurns invalides ·
#   allowlist Agent(...)/Task(...)/Bash(...)/etc malformée (parenthèse non fermée, allowlist
#   vide, entrée vide, espace avant la parenthèse, token hors charset).
# WARNING : skills absent · skill déclaré introuvable (ERROR en --strict) · description < 30c ·
#   tools absent (hérite tout) · champ inconnu · name ≠ nom de fichier · outil hors du set
#   fermé documenté (ERROR en --strict) · nom d'agent non résolu dans une allowlist Agent(...)
#   (reste WARNING même en --strict — voir plus bas ; ERROR seulement sous
#   --resolve-agents=strict) · `Agent` nu sans allowlist (« dispatch non cloisonné »).
#
# --strict NE DURCIT PAS la résolution de noms d'agents (contrairement au reste) : un lint par
# module (un `--agents-dir` à la fois) ne connaît jamais l'univers complet des agents — durcir
# ce point ferait passer en rouge des dizaines d'entrées parfaitement saines (cross-module,
# types natifs futurs, agents tiers). Le monde fermé est strictement OPT-IN via
# --resolve-agents=strict (+ --agent-registry-dir répétés pour élargir l'univers connu) — c'est
# la CI seule (union de tous les plugin/*/agents) qui a la légitimité de l'activer.
#
# --third-party-prefix (défaut "gsd-") ACCUMULE au-dessus du défaut à chaque répétition (le
# premier --no-third-party-prefix rencontré vide la liste avant d'accumuler à nouveau — ordre
# des arguments respecté, comme tout flag CLI répétable). Il a deux effets : (a) un FICHIER
# agent dont le name matche un préfixe n'est plus linté du tout pour la charte VibeFlow (ce
# n'est pas notre agent) ; (b) une ENTRÉE d'allowlist qui matche est réputée résolvable
# (silencieuse). Les deux sont comptés et imprimés SÉPARÉMENT dans le résumé (fichiers non
# lintés ≠ entrées d'allowlist résolues — deux choses différentes, jamais un skip muet ni un
# skip mal décrit).
#
# --hook n'imprime les avertissements QUE lorsqu'il y en a (une ligne compacte avec le compte,
# renvoyant vers l'invocation explicite pour le détail) ; silence total en régime nominal (0 erreur,
# 0 avertissement). Les erreurs, quand il y en a, priment et remplacent ce résumé — le mode reste
# minimal, jamais une énumération ligne par ligne au SessionStart (le signal complet est sur
# l'appel explicite/CI).
#
# Résolution d'un skill déclaré (UAT F2) : d'abord par NOM DE DOSSIER (.claude/skills/<s>/SKILL.md),
# sinon par le frontmatter `name:` des SKILL.md installés — un skill peut porter un name différent
# de son dossier (ex. module planning-core → skill `vf-planning`).
#
# INVARIANTS DE DOCTRINE (Phase 42, spec fabrique §4) — BLOQUANTS dans tous les modes (D-11) :
# ce ne sont jamais des avertissements, quel que soit --strict — check-blueprints.sh (qui appelle
# ce gate en mode par défaut) les voit donc aussi. Chacun a son jumeau négatif et sa mutation
# prouvée rouge (MUT-I1, MUT-I4, MUT-I7, plus MUT-I5/MUT-I6 selon l'arbitrage D-08, 42-05 Tâche 3).
#   I1 (D-06) : `vf-internal: true` doit coïncider, dans les DEUX sens, avec le marqueur littéral
#     « Worker interne » (sensible à la casse) dans `description:`. Écart assumé par rapport à la
#     spec §4 : le marqueur est lu dans `description:`, jamais dans le corps de l'agent, et le
#     nombre de dispatcheurs nommés après le marqueur n'entre jamais en ligne de compte (D-18).
#   I4 : `disallowedTools` ne tolère AUCUN jeton porteur d'un spécifieur parenthésé
#     (`Bash(rm:*)`) : il retire l'outil ENTIER, il ne le restreint pas — un spécifieur y laisse
#     croire à une restriction fine qui n'existe pas côté runtime.
#   I7 : toute clé de frontmatter commençant par `vf-mcp-` exige `vf-requires` citant
#     l'identifiant `mcp-servers` — même jointure que la règle 4 de
#     plugin/dev-orchestrator/scripts/check-capability-activation.sh.
#   I6 (D-07) : un agent dont l'allowlist `Agent(...)/Task(...)` de `tools:` est non vide
#     (analyse pure `allowlist_agents`, jamais un second tokenizer) ET qui ne porte pas
#     `vf-internal: true` est un MANAGER au sens de cet invariant — il doit porter `SendMessage`
#     dans `tools:`, sinon il est muet vis-à-vis de ses pairs. Écart assumé par rapport à la
#     spec §4 : un agent interne qui dispatche (`vf-coder`, `vf-reviewer`, `vf-auditer`,
#     `vf-test-orchestrator` — des workers internes du team-kernel) n'est jamais un manager ici ;
#     un `Agent` nu sans allowlist parenthésée non plus (rien à notifier).
#   I5 (D-08) : un agent dont `disallowedTools:` retire À LA FOIS `Write` ET `Edit` ET dont
#     l'allowlist de dispatch (même analyse pure) est VIDE est un JUGE au sens de cet invariant —
#     il doit porter `omitClaudeMd: true`, sinon il charge la doctrine du `CLAUDE.md` du projet
#     malgré son regard censé être frais. Écart assumé : un agent porteur d'une allowlist non
#     vide (forme `vf-reviewer`/`vf-auditer` — un dispatcheur qui garde le `CLAUDE.md` du projet
#     dont il a besoin pour relire) n'est jamais un juge ici, quel que soit son
#     `disallowedTools:`. Arbitrage D-08 (maintenir) : session principale, décision déléguée par
#     Willy au head (« tranche et avançons »), 2026-09-25 — 42-D19-MESURE.md.
#
# Codes de sortie : 0 = conforme · 1 = non conforme (agents non conformes, OU invocation
#   invalide — ex. --resolve-agents=<valeur inconnue>) · 3 = INDÉTERMINÉ (--strict sur cible
#   absente/vide : aucun verdict rendu — un vert sans rien vérifier serait un faux vert, F13).
#   D-20 (Phase 42) : hors --hook, une cible ABSENTE (dossier introuvable) sort désormais
#   INDÉTERMINÉ (exit 3, jeton CIBLE-ABSENTE) dans tous les modes, y compris sans --strict — une
#   cible PRÉSENTE mais vide garde le régime F13 déjà documenté ci-dessus, inchangé.
#   --allow-empty tolère aussi une cible ABSENTE, au même titre qu'une cible vide.
#   Fraîcheur (Phase 42, FABR-02, D-04) : hors --hook, sous --manifest-freshness=strict, un
#   manifeste périmé rend aussi INDÉTERMINÉ (exit 3, jeton MANIFESTE-PERIME) — jamais la ligne
#   « ✓ agents conformes ». Sans l'option (défaut lenient), un manifeste périmé reste un
#   avertissement, jamais un exit 3 ni un exit 1.

set -uo pipefail

AGENTS_DIR=".claude/agents"
SKILLS_DIR=".claude/skills"
STRICT=false
HOOK_MODE=false
ALLOW_EMPTY=false
SINGLE_FILE=""
THIRD_PARTY_PREFIXES="gsd-"
RESOLVE_AGENTS="lenient"
REGISTRY_DIRS=""
MANIFEST_FRESHNESS="lenient"

for arg in "$@"; do
  case "$arg" in
    --strict)         STRICT=true ;;
    --hook)           HOOK_MODE=true ;;
    --allow-empty)    ALLOW_EMPTY=true ;;
    --file)           : ;; # valeur au prochain arg — géré ci-dessous
    --agents-dir=*)   AGENTS_DIR="${arg#*=}" ;;
    --skills-dir=*)   SKILLS_DIR="${arg#*=}" ;;
    --third-party-prefix=*)
      v="${arg#*=}"
      if [ -z "$THIRD_PARTY_PREFIXES" ]; then THIRD_PARTY_PREFIXES="$v"; else THIRD_PARTY_PREFIXES="$THIRD_PARTY_PREFIXES:$v"; fi
      ;;
    --no-third-party-prefix) THIRD_PARTY_PREFIXES="" ;;
    --resolve-agents=*) RESOLVE_AGENTS="${arg#*=}" ;;
    --agent-registry-dir=*)
      v="${arg#*=}"
      if [ -z "$REGISTRY_DIRS" ]; then REGISTRY_DIRS="$v"; else REGISTRY_DIRS="$REGISTRY_DIRS:$v"; fi
      ;;
    --manifest-freshness=*) MANIFEST_FRESHNESS="${arg#*=}" ;;
    -h|--help)        grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  esac
done
# --file <path> (2 args)
prev=""
for arg in "$@"; do
  [ "$prev" = "--file" ] && SINGLE_FILE="$arg"
  prev="$arg"
done

# --resolve-agents ne connaît QUE lenient|strict — toute autre valeur (typo type "stricts")
# dégraderait silencieusement le gate monde fermé en vert si on la laissait passer (le code
# n'aurait alors testé que == "strict" et serait tombé en lenient sans un mot). Rejet explicite,
# exit 1 : jamais un skip muet, à l'image du contrat F13 déjà appliqué plus bas (cible vide).
case "$RESOLVE_AGENTS" in
  lenient|strict) ;;
  *)
    echo "[check-agents] ✗ --resolve-agents invalide '$RESOLVE_AGENTS' — attendu lenient|strict" >&2
    exit 1
    ;;
esac

# --manifest-freshness : même régime que --resolve-agents ci-dessus (D-14, Phase 42) — toute
# valeur hors lenient|strict est un rejet explicite, jamais un repli muet sur lenient (qui
# masquerait silencieusement un manifeste périmé en CI).
case "$MANIFEST_FRESHNESS" in
  lenient|strict) ;;
  *)
    echo "[check-agents] ✗ --manifest-freshness invalide '$MANIFEST_FRESHNESS' — attendu lenient|strict" >&2
    exit 1
    ;;
esac

# --- Traduction du silence interne vers le harness (D-06/D-07, uniquement sous --hook) ----------
# hook_exit <code> : sous --hook, le SEUL code de silence interne (3 = INDETERMINE sur cible vide
# en --strict) devient 0 à la frontière du harness. Posée ici, au point où le SHELL rend la main
# (pas à l'intérieur du bloc Python embarqué) — le contrat interne du bloc Python ne change pas :
# il continue de rendre 3 pour l'INDETERMINE, avec ou sans --hook (voir plus bas, la condition
# `and not hook` disparaît du DÉCLENCHEMENT de l'exit, jamais du choix d'imprimer ou non). 0 et 1
# ne sont JAMAIS traduits. Sans --hook (CLI, suites de tests), le code recu ressort inchange. Voir
# docs/HOOKS-CONTRAT-SORTIE.md §2 et l'entree #2 de l'inventaire.
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK_MODE" = true ] && [ "$code" -eq 3 ]; then
    exit 0
  fi
  exit "$code"
}

# D-01/D-03 : chemin du manifeste daté dérivé du dossier du script (patron check-blueprints.sh),
# JAMAIS de l'environnement appelant ni du cwd — aucune option de substitution du manifeste.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VF_MANIFEST="$SCRIPT_DIR/check-agents-manifest.json"

# ADR-054 : stub Microsoft Store — `python3` présent dans le PATH mais inerte. Détection par
# CHEMIN (zéro spawn), repli `python` ; sinon message + exit 0 (advisory, comme avant).
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else echo "[check-agents] python3 requis" >&2; exit 0; fi ;;
esac

VF_AGENTS_DIR="$AGENTS_DIR" VF_SKILLS_DIR="$SKILLS_DIR" VF_STRICT="$STRICT" \
VF_HOOK="$HOOK_MODE" VF_SINGLE="$SINGLE_FILE" VF_ALLOW_EMPTY="$ALLOW_EMPTY" \
VF_THIRD_PARTY_PREFIXES="$THIRD_PARTY_PREFIXES" VF_RESOLVE_AGENTS="$RESOLVE_AGENTS" \
VF_REGISTRY_DIRS="$REGISTRY_DIRS" VF_MANIFEST="$VF_MANIFEST" \
VF_MANIFEST_FRESHNESS="$MANIFEST_FRESHNESS" "$PYBIN" -c "
import glob, json, os, re, sys
from datetime import date

manifest_path = os.environ[\"VF_MANIFEST\"]
agents_dir = os.environ[\"VF_AGENTS_DIR\"]
skills_dir = os.environ[\"VF_SKILLS_DIR\"]
strict = os.environ[\"VF_STRICT\"] == \"true\"
hook = os.environ[\"VF_HOOK\"] == \"true\"
allow_empty = os.environ[\"VF_ALLOW_EMPTY\"] == \"true\"
single = os.environ[\"VF_SINGLE\"]
third_party_prefixes = [p for p in os.environ.get(\"VF_THIRD_PARTY_PREFIXES\", \"\").split(\":\") if p]
resolve_agents_strict = os.environ.get(\"VF_RESOLVE_AGENTS\", \"lenient\") == \"strict\"
registry_dirs = [p for p in os.environ.get(\"VF_REGISTRY_DIRS\", \"\").split(\":\") if p]
manifest_freshness_strict = os.environ.get(\"VF_MANIFEST_FRESHNESS\", \"lenient\") == \"strict\"

# Conventions VibeFlow restees en dur (D-01 borne le manifeste aux SIX listes d'origine native ;
# ces quatre champs sont des conventions du depot, jamais sujettes a la peremption d'une doc
# Anthropic externe) : vf-internal (worker interne — pas de commande d'incarnation, cf. Pattern 12) ;
#   vf-mcp-consumer (agent exécutant recevant l'allowlist MCP dérivée du lab à l'install, ADR-051) ;
#   vf-mcp-tools (allowlist MCP NOMMÉE — un serveur, une liste d'outils explicites — consommée par
#   le script d'injection du module dev-orchestrator ; coexiste avec vf-mcp-consumer sans le remplacer) ;
#   vf-requires (identifiant de précondition externe déclarée par l'artefact — jointure par id avec
#   # vf-provides: côté script, consommée par la règle 4 de check-capability-activation.sh, Phase 28).
VIBEFLOW_FIELDS = {\"vf-internal\", \"vf-mcp-consumer\", \"vf-mcp-tools\", \"vf-requires\"}
MEMORY = {\"user\", \"project\", \"local\"}
NOT_AGENTS = {\"contracts.md\", \"README.md\", \"AGENTS.md\"}
# Task = alias legacy d'Agent depuis Claude Code v2.1.63 — traite a l'identique partout.
AGENT_TOOL_NAMES = {\"Agent\", \"Task\"}

# D-01/D-02/D-03 : les six listes de reference (identifiants d'outils, champs de frontmatter,
# types natifs, modeles, modes de permission, niveaux d'effort) ne vivent plus ici — elles sont
# chargees depuis le manifeste daté check-agents-manifest.json (meme dossier que ce script).
# AUCUNE valeur par defaut n'est portee par ce script (D-02) : un manifeste absent, illisible ou
# au schema invalide est un refus explicite (D-03), jamais une liste vide qui laisse tout passer.
_VALEUR_RE = re.compile(r\"^[A-Za-z0-9_-]+$\")

def charger_manifeste(chemin):
    \"\"\"Lit et valide le manifeste daté — toute absence/malformation leve une ValueError qui
    nomme la cle et le motif (jamais un defaut silencieux, jamais un skip ligne a ligne).\"\"\"
    with open(chemin, encoding=\"utf-8\") as fh:
        m = json.load(fh)
    if not isinstance(m, dict):
        raise ValueError(\"racine du manifeste — attendu un objet JSON\")
    cles_racine = {\"valide_jours\", \"rafraichissement\", \"listes\"}
    for cle in cles_racine:
        if cle not in m:
            raise ValueError(f\"cle de premier niveau manquante — {cle}\")
    extra = set(m.keys()) - cles_racine
    if extra:
        raise ValueError(f\"cle(s) de premier niveau inconnue(s) — {sorted(extra)}\")
    valide_jours = m[\"valide_jours\"]
    if not isinstance(valide_jours, int) or isinstance(valide_jours, bool) or valide_jours <= 0:
        raise ValueError(\"valide_jours — attendu un entier strictement positif\")
    listes = m[\"listes\"]
    if not isinstance(listes, dict):
        raise ValueError(\"listes — attendu un objet JSON\")
    cles_listes = {\"outils\", \"champs_frontmatter\", \"types_natifs\", \"modeles\", \"modes_permission\", \"niveaux_effort\"}
    if set(listes.keys()) != cles_listes:
        raise ValueError(f\"listes — attendu exactement les six cles {sorted(cles_listes)}, trouve {sorted(listes.keys())}\")
    for nom_liste, liste in listes.items():
        if not isinstance(liste, dict):
            raise ValueError(f\"listes.{nom_liste} — attendu un objet JSON\")
        verifie_le = liste.get(\"verifie_le\")
        if not isinstance(verifie_le, str):
            raise ValueError(f\"listes.{nom_liste}.verifie_le — attendu une date ISO\")
        try:
            date.fromisoformat(verifie_le)
        except ValueError:
            raise ValueError(f\"listes.{nom_liste}.verifie_le — date ISO invalide ({verifie_le})\")
        source = liste.get(\"source\")
        if not isinstance(source, str) or not source.startswith(\"https://\"):
            raise ValueError(f\"listes.{nom_liste}.source — attendu une chaine https:// ({source})\")
        valeurs = liste.get(\"valeurs\")
        if not isinstance(valeurs, list) or not valeurs:
            raise ValueError(f\"listes.{nom_liste}.valeurs — attendu une liste non vide\")
        for v in valeurs:
            if not isinstance(v, str) or not _VALEUR_RE.fullmatch(v):
                raise ValueError(f\"listes.{nom_liste}.valeurs — valeur hors charset [A-Za-z0-9_-]+ ({v!r})\")
    return m

KNOWN = TOOL_NAMES = NATIVE_TYPES = MODELS = PERM = EFFORT = None
MODELS_ORDERED = EFFORT_ORDERED = []
# Fraîcheur (Phase 42, FABR-02, D-02/D-04/D-05) : defauts surs si charger_referentiel() n'est
# JAMAIS appelee (ex. --file sur une cible introuvable) — une cible non jugee ne peut jamais
# etre consideree perimee, et le rapport de fraicheur ci-dessous reste silencieux dans ce cas.
perimees = []
retrograder = False

def manifeste_perime(manifest, aujourd_hui):
    \"\"\"Rend, dans l'ordre des listes, une description par liste PERIMEE (D-02) : verifie_le
    posterieur a aujourd'hui (DATE-FUTURE, non verifiable — horloge forgee, T-42-13) ; ou age en
    jours strictement superieur a valide_jours (l'un et l'autre LUS dans le manifeste, aucune
    valeur par defaut de validite ici, D-02). Liste vide = manifeste frais.\"\"\"
    valide_jours = manifest[\"valide_jours\"]
    descriptions = []
    for nom_liste, liste in manifest[\"listes\"].items():
        verifie_le = date.fromisoformat(liste[\"verifie_le\"])
        if verifie_le > aujourd_hui:
            descriptions.append(f\"{nom_liste} (DATE-FUTURE : verifiee le {verifie_le.isoformat()}, posterieure a aujourd'hui — non verifiable)\")
            continue
        age = (aujourd_hui - verifie_le).days
        if age > valide_jours:
            descriptions.append(f\"{nom_liste} (verifiee le {verifie_le.isoformat()}, {age} j, validite {valide_jours} j)\")
    return descriptions

def charger_referentiel():
    \"\"\"Charge le manifeste (D-01/D-03) et peuple les ensembles/ordres consommes par le lint.
    Appelee SEULEMENT s'il existe au moins une cible a juger (chargement PARESSEUX) — la branche
    cible vide (F13, exit 3 en --strict / 0 sinon) ne l'appelle jamais et reste inchangee ; la
    fraicheur (perimees/retrograder) n'est donc, elle non plus, JAMAIS evaluee sur cible vide.\"\"\"
    global KNOWN, TOOL_NAMES, NATIVE_TYPES, MODELS, PERM, EFFORT, MODELS_ORDERED, EFFORT_ORDERED
    global perimees, retrograder
    try:
        m = charger_manifeste(manifest_path)
    except (OSError, ValueError) as e:
        cause = str(e).replace(\" : \", \" - \")
        print(f\"[check-agents] ✗ MANIFESTE-ILLISIBLE ({manifest_path}) — {cause} — aucun verdict rendu (D-03)\")
        sys.exit(0 if hook else 1)
    listes = m[\"listes\"]
    KNOWN = set(listes[\"champs_frontmatter\"][\"valeurs\"]) | VIBEFLOW_FIELDS
    TOOL_NAMES = set(listes[\"outils\"][\"valeurs\"])
    NATIVE_TYPES = set(listes[\"types_natifs\"][\"valeurs\"])
    MODELS_ORDERED = list(listes[\"modeles\"][\"valeurs\"])
    MODELS = set(MODELS_ORDERED)
    PERM = set(listes[\"modes_permission\"][\"valeurs\"])
    EFFORT_ORDERED = list(listes[\"niveaux_effort\"][\"valeurs\"])
    EFFORT = set(EFFORT_ORDERED)
    # Cibles de mutation MUT-F1/MUT-F2 (42-04) : DEUX lignes distinctes et uniques dans le
    # fichier, jamais fusionnees — la mutation de l'une ne doit jamais affecter l'autre.
    perimees = manifeste_perime(m, date.today())
    retrograder = bool(perimees)

errors, warnings = [], []
# Deux compteurs DISTINCTS (jamais un skip mal decrit) : thirdparty_files_total = fichiers
# .md entiers exclus du lint (name matche un prefixe tiers) ; thirdparty_entries_total =
# entrees d'allowlist Agent(...)/Task(...) reputees resolvables via un prefixe tiers. Ce
# sont deux populations differentes — un agent peut avoir 0 fichier tiers et 30 entrees
# tierces dans ses allowlists, ou l'inverse.
thirdparty_files_total = 0
thirdparty_entries_total = 0

def parse_frontmatter(text):
    lines = text.split(\"\n\")
    if not lines or lines[0].strip() != \"---\":
        return None
    fm, i = {}, 1
    current_key = None
    while i < len(lines):
        line = lines[i]
        if line.strip() == \"---\":
            return fm
        m = re.match(r\"^([A-Za-z_-]+):\s*(.*)$\", line)
        if m:
            current_key = m.group(1)
            val = m.group(2).strip()
            if val.startswith(\"[\") and val.endswith(\"]\"):
                items = [x.strip().strip(chr(34)).strip(chr(39)) for x in val[1:-1].split(\",\") if x.strip()]
                fm[current_key] = items
            elif val == \"\" or val == \">\" or val == \"|\":
                # val vide : typage DIFFERE (str par defaut, converti en liste a la 1re puce) —
                # un plain scalar multi-ligne indente est du YAML valide (etait perdu avant).
                fm[current_key] = \"\" if val == \"\" else val
            else:
                # Dequotage des scalaires : name: \"x\" / model: 'sonnet' sont du YAML valide
                # (parfois OBLIGATOIRE, ex. description contenant ': ') — le runtime les accepte.
                if len(val) >= 2 and val[0] == val[-1] and val[0] in (chr(34), chr(39)):
                    val = val[1:-1]
                fm[current_key] = val
        elif current_key is not None:
            item = re.match(r\"^\s+-\s+(.+?)(\s+#.*)?$\", line)
            if item and isinstance(fm.get(current_key), list):
                fm[current_key].append(item.group(1).strip().strip(chr(34)).strip(chr(39)))
            elif item and fm.get(current_key) == \"\":
                fm[current_key] = [item.group(1).strip().strip(chr(34)).strip(chr(39))]
            elif line.startswith(\"  \") and isinstance(fm.get(current_key), str):
                fm[current_key] = (fm[current_key] + \" \" + line.strip()).strip()
        i += 1
    return None  # frontmatter jamais ferme

def frontmatter_lines(text):
    \"\"\"Retourne les lignes BRUTES entre les deux '---' (pour la re-tokenisation des
    allowlists Agent(...), qui doit repartir de la ligne source, jamais de fm[] deja mangle).\"\"\"
    lines = text.split(\"\n\")
    if not lines or lines[0].strip() != \"---\":
        return None
    for idx in range(1, len(lines)):
        if lines[idx].strip() == \"---\":
            return lines[1:idx]
    return None

_KEY_RE = re.compile(r\"^([A-Za-z_-]+):\s*(.*)$\")

def extract_raw_field(fmlines, key):
    \"\"\"Extrait la valeur BRUTE (non tokenisee) d'un champ tools:/disallowedTools:.
    Retourne (mode, raw) : mode='block' -> raw est deja une liste de tokens (puces YAML) ;
    mode in ('flow','scalar') -> raw est une chaine brute a re-tokeniser a profondeur de
    parentheses. (None, None) si la cle est absente. Mirrore le comportement de continuation
    de parse_frontmatter (ligne indentee >= 2 espaces) — une continuation NON indentee est
    perdue ici EXACTEMENT comme dans parse_frontmatter (la perte se traduit en parenthese
    non fermee au niveau du tokenizer, ce qui est le comportement voulu).
    \"\"\"
    if fmlines is None:
        return None, None
    n = len(fmlines)
    for idx in range(n):
        m = _KEY_RE.match(fmlines[idx])
        if not (m and m.group(1) == key):
            continue
        val = m.group(2).strip()
        k = idx + 1
        if val == \"\":
            bullets = []
            while k < n:
                # Une ligne vide (ou toute ligne non-puce qui n'ouvre pas une nouvelle
                # cle) est TOLEREE au milieu du bloc — a l'image de parse_frontmatter,
                # qui ne casse jamais sur une ligne vide. Seule une nouvelle cle:
                # (_KEY_RE) marque la fin LEGITIME du bloc. Avant ce correctif, un
                # simple 'break' ici faisait perdre SILENCIEUSEMENT toute puce suivant
                # une ligne vide (defaut 2, F13-like : zero warning sur l'entree perdue).
                if _KEY_RE.match(fmlines[k]):
                    break
                item = re.match(r\"^\s+-\s+(.+?)(\s+#.*)?$\", fmlines[k])
                if item:
                    bullets.append(item.group(1).strip())
                k += 1
            if bullets:
                return \"block\", bullets
            parts = []
            while k < n and fmlines[k].startswith(\"  \") and fmlines[k].strip() and not _KEY_RE.match(fmlines[k]):
                parts.append(fmlines[k].strip())
                k += 1
            return \"scalar\", \" \".join(parts)
        else:
            parts = [val]
            while k < n and fmlines[k].startswith(\"  \") and fmlines[k].strip() and not _KEY_RE.match(fmlines[k]):
                parts.append(fmlines[k].strip())
                k += 1
            raw = \" \".join(parts).strip()
            if raw.startswith(\"[\"):
                return \"flow\", raw
            return \"scalar\", raw
    return None, None

def split_depth(raw):
    \"\"\"Split a profondeur de parentheses (jamais un split(',') naif) — c'est ce qui
    laisse 'Agent(vf-coder, vf-reviewer)' intact comme UN token. Retourne (tokens, depth) ou
    depth est le solde ouvertures-fermetures EN SIGNE (0 = equilibre ; > 0 = il manque des
    fermetures ; < 0 = il y a des fermetures EN TROP, ex. 'Agent(a))') — la distinction de
    signe permet a l'appelant de ne pas dire \"non fermee\" quand le vrai probleme est l'inverse.\"\"\"
    tokens, depth, cur = [], 0, []
    for ch in raw:
        if ch == \"(\":
            depth += 1
            cur.append(ch)
        elif ch == \")\":
            depth -= 1
            cur.append(ch)
        elif ch == \",\" and depth == 0:
            tokens.append(\"\".join(cur))
            cur = []
        else:
            cur.append(ch)
    tokens.append(\"\".join(cur))
    return tokens, depth

def dequote_scalar(s):
    \"\"\"Retire UNE seule paire de guillemets englobante (\" ou ') — calque exact du
    dequotage deja applique aux scalaires par parse_frontmatter (l.195-196). Sans ca,
    'tools: \"Read, Write, Agent(vf-coder)\"' (YAML valide) etait tokenise caracteres-
    litteraux-compris et produisait de faux BLOQUANTS (charset, parenthese non fermee).\"\"\"
    if len(s) >= 2 and s[0] == s[-1] and s[0] in (chr(34), chr(39)):
        return s[1:-1]
    return s

def tokenize_field(mode, raw):
    \"\"\"mode='block' : raw deja une liste de tokens individuels (puces YAML).
    mode in ('flow','scalar') : raw est une chaine — on la dequote d'abord (voir
    dequote_scalar), on retire les crochets [ ] de la flow list puis on decoupe a
    profondeur de parentheses. Retourne (tokens, depth) — voir split_depth pour le signe.\"\"\"
    if mode == \"block\":
        return [dequote_scalar(t) for t in raw], 0
    s = dequote_scalar(raw.strip())
    if s.startswith(\"[\") and s.endswith(\"]\"):
        s = s[1:-1]
    return split_depth(s)

def parse_token(raw_tok, field, base):
    \"\"\"Analyse structurelle PURE d'UN token d'allowlist deja isole par tokenize_field.
    AUCUN effet de bord (jamais rappelee pour classer un agent — Phase 42, § Don't Hand-Roll).
    Retourne (tool_name, agent_names, message_ou_None) : agent_names est None si pas de
    parametres, [] si allowlist vide 'Agent()', une liste sinon ; message_ou_None est le
    message d'erreur de SYNTAXE (meme texte EXACT que l'ancien analyze_token), ou None si le
    token est syntaxiquement propre — un token AVEC message n'est jamais retenu dans une
    allowlist consommee ailleurs (allowlist_agents), meme quand il rend des agent_names non
    vides (ex. 'Agent(a,,b)' : agent_names=['a','b'] mais message present -> jamais dispatch).\"\"\"
    tok = raw_tok.strip()
    if tok == \"\":
        return None, None, f\"{base} : {field} — entree d'allowlist vide (virgule orpheline, ex. 'a,,b')\"
    m_space = re.match(r\"^(\S+)\s+\(\", tok)
    if m_space:
        return None, None, f\"{base} : {field} — espace avant la parenthese dans '{tok}' (attendu Nom(args))\"
    m = re.match(r\"^([A-Za-z0-9_-]+)\((.*)$\", tok, re.S)
    if not m:
        # pas de parenthese : nom d'outil seul (Read, Bash, ...) OU forme MCP a joker TERMINAL
        # 'mcp__<serveur>__*' — la forme sure documentee en tete d'inject-mcp-tools.sh ADR-051
        # (\"on injecte donc, par serveur, la forme sure mcp__<serveur>__*\"). Aucun joker ailleurs :
        # ni en tete, ni en milieu de chaine, ni dans le nom du serveur, ni suivi d'un suffixe
        # (mcp__*, mcp__Xcode*MCP__*, mcp__XcodeBuildMCP__*_sim restent hors charset).
        if not (re.fullmatch(r\"[A-Za-z0-9_-]+\", tok) or re.fullmatch(r\"mcp__[A-Za-z0-9_-]+__[*]\", tok)):
            return None, None, f\"{base} : {field} — token hors charset attendu '{tok}'\"
        return tok, None, None
    name, rest = m.group(1), m.group(2)
    if not rest.endswith(\")\"):
        return name, None, f\"{base} : {field} — parenthese non fermee dans '{tok}'\"
    inner = rest[:-1]
    if inner.strip() == \"\":
        return name, [], f\"{base} : {field} — allowlist vide '{name}()'\"
    agent_names = [a.strip() for a in inner.split(\",\") if a.strip() != \"\"]
    if len(agent_names) != len([a for a in inner.split(\",\")]):
        return name, agent_names, f\"{base} : {field} — entree vide dans l'allowlist de '{name}(...)'\"
    return name, agent_names, None

def analyze_token(raw_tok, field, base):
    \"\"\"Enveloppe historique d'analyze_token : appelle parse_token (analyse pure) et ajoute
    son message a errors sous la forme EXACTE d'aujourd'hui (T26, T27, T37 a T41 assertent ces
    textes). Comportement inchange pour tout appelant existant.\"\"\"
    name, agent_names, message = parse_token(raw_tok, field, base)
    if message is not None:
        errors.append(message)
    return name, agent_names

def allowlist_agents(fmlines):
    \"\"\"I6 (D-07) : analyse PURE du champ tools: — jetons via extract_raw_field + tokenize_field
    (memes fonctions que le lint principal, jamais un second tokenizer). Liste vide si le champ
    est absent ou si la profondeur de parentheses est non nulle. Pour chaque jeton SANS message
    d'erreur (parse_token) dont le nom est un outil de dispatch (AGENT_TOOL_NAMES) avec une
    allowlist non vide, accumule ses noms d'agents — jamais analyze_token (qui ecrirait dans
    errors une seconde fois, § Don't Hand-Roll : parse_token pur alimente cette fonction).\"\"\"
    mode, raw = extract_raw_field(fmlines, \"tools\")
    if mode is None:
        return []
    tokens, depth = tokenize_field(mode, raw)
    if depth != 0:
        return []
    dispatch = []
    for raw_tok in tokens:
        name, agent_names, message = parse_token(raw_tok, \"tools\", \"\")
        if message is not None or name is None:
            continue
        if name in AGENT_TOOL_NAMES and agent_names:
            dispatch.extend(agent_names)
    return dispatch

def resolve_agent_name(name, agents_dir_local, registry_dirs_local, prefixes):
    low = name.lower()
    if low in NATIVE_TYPES:
        return \"native\"
    for pfx in prefixes:
        if pfx and name.startswith(pfx):
            return \"thirdparty\"
    if os.path.isfile(os.path.join(agents_dir_local, name + \".md\")):
        return \"resolved\"
    for rd in registry_dirs_local:
        if rd and os.path.isfile(os.path.join(rd, name + \".md\")):
            return \"resolved\"
    return \"unresolved\"

def lint_tool_field(base, field, mode, raw, do_agent_resolution):
    \"\"\"Applique le tokenizer + la classification a un champ tools:/disallowedTools:.\"\"\"
    global thirdparty_entries_total
    tokens, depth = tokenize_field(mode, raw)
    if depth > 0:
        errors.append(f\"{base} : {field} — parenthese non fermee (il manque {depth} fermeture(s), allowlist tronquee ou mal formee, verifier l'indentation de la continuation)\")
        return
    if depth < 0:
        errors.append(f\"{base} : {field} — parenthese fermante en trop ({-depth} de trop, verifier '{raw}')\")
        return
    bare_agent = False
    for raw_tok in tokens:
        name, agent_names = analyze_token(raw_tok, field, base)
        if name is None:
            continue
        is_agent_tool = name in AGENT_TOOL_NAMES
        if name not in TOOL_NAMES and not is_agent_tool and not name.startswith(\"mcp__\"):
            msg = f\"{base} : {field} — outil hors du set connu '{name}' (typo ? nouvel outil non encore reference ?)\"
            # D-05 (Phase 42) : un manifeste perime ne peut plus REFUSER sur cette liste fermee —
            # erreur seulement si strict ET manifeste frais ; sinon avertissement, suffixe
            # [MANIFESTE-PERIME — retrograde en avertissement, D-05] uniquement quand c'est bien
            # la peremption qui a evite le refus (jamais sur le regime lenient normal).
            if strict and not retrograder:
                errors.append(msg)
            else:
                if retrograder:
                    msg += \" [MANIFESTE-PERIME — retrograde en avertissement, D-05]\"
                warnings.append(msg)
        if is_agent_tool:
            if agent_names is None:
                if field == \"tools\":
                    bare_agent = True
            elif do_agent_resolution:
                for a in agent_names:
                    verdict = resolve_agent_name(a, agents_dir, registry_dirs, third_party_prefixes)
                    if verdict == \"thirdparty\":
                        thirdparty_entries_total += 1
                    elif verdict == \"unresolved\":
                        msg = f\"{base} : {field} — nom d'agent non resolu '{a}' (ni type natif, ni fichier {agents_dir}/{a}.md, ni registre)\"
                        # D-05 (Phase 42) : meme regime que ci-dessus — erreur sous
                        # --resolve-agents=strict seulement si le manifeste est frais.
                        if resolve_agents_strict and not retrograder:
                            errors.append(msg + \" [--resolve-agents=strict]\")
                        else:
                            if retrograder:
                                msg += \" [MANIFESTE-PERIME — retrograde en avertissement, D-05]\"
                            warnings.append(msg)
    if bare_agent:
        warnings.append(f\"{base} : tools — 'Agent' sans allowlist parenthesee = dispatch non cloisonne\")

# UAT F2 : carte frontmatter name: → chemin SKILL.md, construite paresseusement UNE fois.
_skill_name_map = None
def skill_name_map():
    global _skill_name_map
    if _skill_name_map is None:
        _skill_name_map = {}
        for sk_path in sorted(glob.glob(os.path.join(skills_dir, \"*\", \"SKILL.md\"))):
            try:
                sk_fm = parse_frontmatter(open(sk_path, encoding=\"utf-8-sig\").read())
            except OSError:
                continue
            if not sk_fm:
                continue
            sk_name = sk_fm.get(\"name\")
            if isinstance(sk_name, str) and sk_name:
                _skill_name_map.setdefault(sk_name, sk_path)
    return _skill_name_map

def resolve_skill(s):
    sk = os.path.join(skills_dir, s, \"SKILL.md\")
    if os.path.isfile(sk):
        return sk
    return skill_name_map().get(s, \"\")

def agent_display_name(path, text):
    fm = parse_frontmatter(text)
    if fm and isinstance(fm.get(\"name\"), str) and fm.get(\"name\"):
        return fm[\"name\"]
    return os.path.basename(path)[:-3]

def bare_tokens(fmlines, field):
    \"\"\"Ensemble des tokens SANS parenthese d'un champ tools:/disallowedTools: — reutilise le
    MEME tokenizer a profondeur de parentheses que le lint principal (extract_raw_field +
    tokenize_field), jamais un second parseur. Un champ absent ou une allowlist mal formee
    (depth != 0) rend un ensemble vide plutot que de lever : ce garde-fou structurel ne doit
    jamais masquer les erreurs de syntaxe deja levees ailleurs par lint_tool_field.\"\"\"
    mode, raw = extract_raw_field(fmlines, field)
    if mode is None:
        return set()
    tokens, depth = tokenize_field(mode, raw)
    if depth != 0:
        return set()
    return {t.strip() for t in tokens if t.strip() and \"(\" not in t}

# ---- Invariants de doctrine locaux (Phase 42, spec fabrique §4, FABR-03) -----------------------
# Toujours des ERREURS (D-11), jamais affectees par --strict. Chaque fonction rend une LISTE de
# messages (jamais un booleen ni une exception) — check_file() les etend a errors via UNE ligne
# d'appel unique par invariant (errors.extend(invariant_iN(...))), cible des mutants MUT-I1/I4/I7.

def invariant_i1(base, fm):
    \"\"\"I1 (D-06) : vf-internal: true doit coincider, dans les DEUX sens, avec le marqueur
    litteral « Worker interne » (sensible a la casse — une variante de casse est traitee comme
    absente) dans description: (chaine ou liste jointe par un espace). Le nombre de dispatcheurs
    nommes apres le marqueur (D-18, forme a deux dispatcheurs) n'entre jamais en ligne de compte :
    seule la PRESENCE du marqueur est lue.\"\"\"
    is_internal = str(fm.get(\"vf-internal\", \"\")) == \"true\"
    desc = fm.get(\"description\")
    if isinstance(desc, list):
        desc_text = \" \".join(str(d) for d in desc)
    else:
        desc_text = str(desc) if desc is not None else \"\"
    has_marker = \"Worker interne\" in desc_text
    if is_internal and not has_marker:
        return [f\"{base} : invariant I1 — vf-internal: true sans le marqueur « Worker interne » dans description: (D-06)\"]
    if has_marker and not is_internal:
        return [f\"{base} : invariant I1 — description: porte « Worker interne » sans vf-internal: true (D-06)\"]
    return []

def invariant_i4(base, fmlines):
    \"\"\"I4 : disallowedTools ne tolere aucun jeton porteur d'un specifieur parenthese — il
    retire l'outil ENTIER, il ne le restreint pas. Jetons via extract_raw_field + tokenize_field
    (memes fonctions que le lint principal, jamais un second tokenizer) ; liste vide si le champ
    est absent ou si la profondeur de parentheses est non nulle (l'erreur de syntaxe correspondante
    est deja levee par lint_tool_field, I4 ne la duplique jamais).\"\"\"
    mode, raw = extract_raw_field(fmlines, \"disallowedTools\")
    if mode is None:
        return []
    tokens, depth = tokenize_field(mode, raw)
    if depth != 0:
        return []
    msgs = []
    for raw_tok in tokens:
        tok = raw_tok.strip()
        if \"(\" in tok:
            msgs.append(f\"{base} : invariant I4 — disallowedTools porte un specifieur '{tok}' : il retire l'outil ENTIER, il ne le restreint pas\")
    return msgs

_VF_REQUIRES_SPLIT_RE = re.compile(r\"[,\s]+\")

def invariant_i7(base, fm):
    \"\"\"I7 : toute cle commencant par vf-mcp- exige vf-requires citant l'identifiant
    mcp-servers — meme jointure (virgules/espaces) que la regle 4 de
    check-capability-activation.sh. vf-requires peut etre une chaine ou une liste.\"\"\"
    mcp_keys = sorted(k for k in fm if k.startswith(\"vf-mcp-\"))
    if not mcp_keys:
        return []
    vr = fm.get(\"vf-requires\")
    tokens = set()
    if isinstance(vr, list):
        for item in vr:
            tokens.update(t for t in _VF_REQUIRES_SPLIT_RE.split(str(item)) if t)
    elif isinstance(vr, str):
        tokens.update(t for t in _VF_REQUIRES_SPLIT_RE.split(vr) if t)
    if \"mcp-servers\" in tokens:
        return []
    return [f\"{base} : invariant I7 — {k} sans vf-requires citant mcp-servers\" for k in mcp_keys]

def invariant_i6(base, fm, fmlines, dispatch):
    \"\"\"I6 (D-07, TOUJOURS arme, independant de l'arbitrage D-19) : manager si dispatch (issu
    de allowlist_agents) non vide ET vf-internal ne vaut pas « true ». Un manager sans
    SendMessage dans bare_tokens(fmlines, \\\"tools\\\") est une erreur — la vue sur ses pairs
    (SendMessage) est requise pour tout dispatcheur non interne. Un agent interne porteur
    d'une allowlist (vf-coder, vf-reviewer, vf-auditer, vf-test-orchestrator), ou un 'Agent' nu
    sans allowlist parenthesee, n'est jamais un manager au sens de cet invariant.\"\"\"
    if not dispatch:
        return []
    if str(fm.get(\"vf-internal\", \"\")) == \"true\":
        return []
    if \"SendMessage\" in bare_tokens(fmlines, \"tools\"):
        return []
    return [f\"{base} : invariant I6 — manager (allowlist Agent(...) non vide, non vf-internal) sans SendMessage dans tools: (D-07)\"]

def invariant_i5(base, fm, fmlines, dispatch):
    \"\"\"I5 (D-08, SEULEMENT SI ARBITRAGE-MAINTENIR au checkpoint D-19, Phase 42 42-05 Tache 3) :
    juge si Write ET Edit sont dans bare_tokens(fmlines, \\\"disallowedTools\\\") ET dispatch (issu
    de allowlist_agents) est vide. Un juge sans omitClaudeMd valant « true » est une erreur — un
    regard frais ne charge pas la doctrine du CLAUDE.md du projet. Un agent porteur d'une
    allowlist Agent(...)/Task(...) non vide (forme vf-reviewer, vf-auditer) n'est jamais un juge
    au sens de cet invariant, quel que soit son disallowedTools.\"\"\"
    disallowed = bare_tokens(fmlines, \"disallowedTools\")
    if not (\"Write\" in disallowed and \"Edit\" in disallowed):
        return []
    if dispatch:
        return []
    if str(fm.get(\"omitClaudeMd\", \"\")) == \"true\":
        return []
    return [f\"{base} : invariant I5 — juge (disallowedTools retire Write et Edit, aucune allowlist Agent(...)) sans omitClaudeMd: true — un regard frais ne charge pas la doctrine (D-08)\"]

def check_file(path):
    base = os.path.basename(path)
    try:
        text = open(path, encoding=\"utf-8-sig\").read()   # utf-8-sig : tolere un BOM d origine externe
    except OSError as e:
        errors.append(f\"{base} : illisible ({e})\")
        return
    fm = parse_frontmatter(text)
    if fm is None:
        errors.append(f\"{base} : AUCUN frontmatter YAML (--- ... ---) — cet agent est invisible pour le routage natif\")
        return

    name = fm.get(\"name\")
    if not name or not isinstance(name, str):
        errors.append(f\"{base} : champ requis manquant — name\")
    else:
        if not re.fullmatch(r\"[a-z0-9-]+\", name):
            errors.append(f\"{base} : name invalide ({name}) — lettres minuscules et tirets uniquement\")
        if name != base[:-3]:
            warnings.append(f\"{base} : name ({name}) different du nom de fichier — source de confusion\")

    desc = fm.get(\"description\")
    if not desc or (isinstance(desc, str) and not desc.strip()) or desc == []:
        errors.append(f\"{base} : champ requis manquant — description (sans elle, agent JAMAIS auto-route)\")
    elif isinstance(desc, str) and len(desc) < 30:
        warnings.append(f\"{base} : description trop courte ({len(desc)}c) pour un routage fiable — inclure quand utiliser cet agent\")

    model = fm.get(\"model\")
    if not model:
        errors.append(f\"{base} : model absent — souverainete modele requise ({'|'.join(MODELS_ORDERED)})\")
    elif model not in MODELS and not re.fullmatch(r\"claude-[a-z0-9.-]+\", str(model)):
        errors.append(f\"{base} : model invalide ({model}) — attendu {'|'.join(MODELS_ORDERED)}|claude-<id>\")

    memory = fm.get(\"memory\")
    if not memory:
        errors.append(f\"{base} : memory absente — scope memoire requis (user|project|local)\")
    elif memory not in MEMORY:
        errors.append(f\"{base} : memory invalide ({memory}) — attendu user|project|local\")

    # effort EXIGE (zone 6, Phase 24 — ADR-044 etendu) : le champ etait valide S IL ETAIT
    # PRESENT, donc omissible en silence — 0 des 25 agents livres le portait. Le bareme est
    # PAR ROLE (pilotage et jugement haut, execution mecanique bas, jamais uniformement) :
    # une omission n est pas un defaut par defaut, c est un role non declare. Meme forme a
    # deux branches que le bloc model ci-dessus, et MEME perimetre : les agents ecartes par
    # --third-party-prefix ne passent jamais ici (skip en amont, boucle principale).
    effort = fm.get(\"effort\")
    if not effort:
        errors.append(f\"{base} : effort absent — bareme par role requis ({'|'.join(EFFORT_ORDERED)})\")
    elif effort not in EFFORT:
        errors.append(f\"{base} : effort invalide ({effort}) — attendu {'|'.join(EFFORT_ORDERED)}\")
    pm = fm.get(\"permissionMode\")
    if pm and pm not in PERM:
        errors.append(f\"{base} : permissionMode invalide ({pm})\")
    iso = fm.get(\"isolation\")
    # Issue #38 : \`isolation: worktree\` est INTERDIT dans le frontmatter d'un agent DISTRIBUE,
    # tant que ses deux preconditions ne le sont pas elles-memes.
    #   1. Le worktree du harness fork depuis la branche PAR DEFAUT, pas depuis le HEAD courant.
    #      La precondition qui corrige ca — \`worktree.baseRef: \"head\"\` — vit dans le settings du
    #      poste ; l'engine ne la pose NULLE PART chez l'utilisateur (verifie : zero occurrence de
    #      \`baseRef\` dans vibeflow-update.sh, merge-hooks.sh et l'installeur). Elle a ete posee
    #      dans le settings local de CE repo en Phase 27, et les 13 agents ont ete distribues sans
    #      elle : le worker atterrit sur une branche technique repartant de la branche par defaut,
    #      sans aucun fichier du mandat.
    #   2. Meme avec baseRef corrige, rien ne ramene les commits du worker vers la branche de la
    #      mission sur un moteur installe (<= 1.10.0). Le merge-back est desormais implemente en
    #      amont (open-gsd/gsd-core#3302, close COMPLETED 2026-08-14 — deja le motif du refus
    #      ecrit de claude_orchestration en Phase 27) mais PAS release : close != release !=
    #      installe. Le re-armement reste gate par la Phase 35 (release > 1.10.0 installee ET
    #      preuve du retour des commits rejouee, WKTR-02).
    # L'isolation reste une decision de DISPATCH du manager (team-kernel.md §Parallelisme), jamais
    # une propriete du worker : portee par le frontmatter elle devient inconditionnelle et retire au
    # manager l'arbitrage que sa propre doctrine lui confie.
    # Lever ce gate demande de distribuer la precondition ET de prouver le retour des commits — pas
    # de supprimer ces lignes.
    if iso == \"worktree\":
        errors.append(f\"{base} : isolation worktree interdite dans un agent distribue (issue #38) — le worktree fork depuis la branche par defaut, la precondition worktree.baseRef n'est pas distribuee, et rien ne ramene les commits. L'isolation est une decision de dispatch du manager.\")
    elif iso:
        errors.append(f\"{base} : isolation invalide ({iso}) — aucune valeur n'est admise dans un agent distribue (voir issue #38)\")
    bg = fm.get(\"background\")
    if bg and str(bg) not in (\"true\", \"false\"):
        errors.append(f\"{base} : background invalide ({bg}) — true|false\")
    mt = fm.get(\"maxTurns\")
    if mt and not str(mt).isdigit():
        errors.append(f\"{base} : maxTurns invalide ({mt}) — entier attendu\")

    skills = fm.get(\"skills\")
    # Gate anti-contournement : skills en chaine plate (skills: a, b) = YAML valide → normaliser
    # en liste, sinon existence/budget/disable-model-invocation etaient silencieusement sautes.
    if isinstance(skills, str) and skills.strip() and skills not in (\">\", \"|\"):
        skills = [s.strip() for s in skills.split(\",\") if s.strip()]
    if not skills:
        warnings.append(f\"{base} : aucun skill cable — agent sans expertise injectee (recommande : skills:)\")
    elif isinstance(skills, list) and os.path.isdir(skills_dir):
        # Budget de prechargement (ADR-044) : skills: injecte le SKILL.md ENTIER au startup
        # de l agent (verite runtime). Precharger = petit et systematique ; le on-demand est
        # le defaut natif (description seule au startup, contenu a l invocation).
        preload_warn = int(os.environ.get(\"VF_PRELOAD_WARN\", \"200\"))
        preload_max = int(os.environ.get(\"VF_PRELOAD_MAX\", \"1200\"))
        total_lines = 0
        for s in skills:
            sk = resolve_skill(s)
            if not sk:
                msg = f\"{base} : skill declare introuvable — {s} (ni dossier .claude/skills/{s}/, ni frontmatter name: correspondant ; le creer via skill-creator, jamais le laisser en promesse)\"
                (errors if strict else warnings).append(msg)
                continue
            try:
                sk_text = open(sk, encoding=\"utf-8\").read()
            except OSError:
                continue
            n = sk_text.count(\"\n\") + 1
            total_lines += n
            if re.search(r\"^disable-model-invocation:\s*true\", sk_text, re.M):
                errors.append(f\"{base} : skill {s} a disable-model-invocation:true — NON prechargeable (restriction runtime), le retirer de skills:\")
            elif re.search(r\"^context:\s*fork\", sk_text, re.M):
                warnings.append(f\"{base} : skill {s} est context:fork (deja isole) — le precharger est contre-productif, laisser on-demand\")
            elif n > preload_warn:
                warnings.append(f\"{base} : skill {s} precharge = {n} lignes (> {preload_warn}) — candidat on-demand (le contenu ENTIER entre au startup)\")
        if total_lines > preload_max:
            errors.append(f\"{base} : budget de prechargement depasse — {total_lines} lignes cumulees (> {preload_max}, VF_PRELOAD_MAX) : basculer les gros skills en on-demand\")

    if \"tools\" not in fm:
        warnings.append(f\"{base} : tools absent — herite de TOUS les outils (restreindre si agent en lecture/analyse)\")

    fmlines = frontmatter_lines(text)
    for field, do_resolution in ((\"tools\", True), (\"disallowedTools\", False)):
        mode, raw = extract_raw_field(fmlines, field)
        if mode is None:
            continue
        lint_tool_field(base, field, mode, raw, do_resolution)

    # Invariants de doctrine locaux (Phase 42, FABR-03) — TOUJOURS des erreurs (D-11), jamais
    # affectees par --strict. Une ligne d'appel UNIQUE par invariant, cible des mutants QUAL-01.
    errors.extend(invariant_i1(base, fm))
    errors.extend(invariant_i4(base, fmlines))
    errors.extend(invariant_i7(base, fm))
    dispatch = allowlist_agents(fmlines)
    errors.extend(invariant_i6(base, fm, fmlines, dispatch))
    errors.extend(invariant_i5(base, fm, fmlines, dispatch))

    # Regle anti-regression (Phase 20) : memory: reinjecte SILENCIEUSEMENT Write+Edit au
    # runtime par-dessus l'allowlist tools: (contrat Claude Code confirme par sonde). Un agent
    # qui porte memory: et dont le tools: (declare) omet Write ET Edit DOIT fermer ce canal
    # explicitement via disallowedTools — sinon rien n'empeche un futur juge/reviewer de naitre
    # sans sa barriere. Purement structurel : reutilise bare_tokens() (meme tokenizer), aucune
    # analyse de texte. Warning en defaut, ERREUR en --strict — meme regime que les autres
    # classes structurelles de ce script (outil hors set connu, skill introuvable) : visible au
    # SessionStart des qu'il y en a un (D-21), bloquant sur l'appel explicite/CI --strict.
    if memory and \"tools\" in fm:
        tools_tokens = bare_tokens(fmlines, \"tools\")
        if \"Write\" not in tools_tokens and \"Edit\" not in tools_tokens:
            disallowed_tokens = bare_tokens(fmlines, \"disallowedTools\")
            if not (\"Write\" in disallowed_tokens and \"Edit\" in disallowed_tokens):
                msg = f\"{base} : memory: + tools: sans Write/Edit exige disallowedTools: Write, Edit (memory: reinjecte silencieusement ces outils au runtime — barriere structurelle requise)\"
                (errors if strict else warnings).append(msg)

    for k in fm:
        if k not in KNOWN:
            warnings.append(f\"{base} : champ inconnu du runtime — {k} (typo ? champ invente ? verifier la doc)\")

if single:
    if os.path.isfile(single):
        charger_referentiel()
        check_file(single)
    else:
        errors.append(f\"fichier introuvable : {single}\")
else:
    # D-20 : une cible ABSENTE (dossier introuvable) est distincte d'une cible PRESENTE et vide —
    # ligne UNIQUE, cible du mutant MUT-D20 (42-04). single vaut toujours une chaine (jamais None :
    # le bash exporte VF_SINGLE=\"$SINGLE_FILE\" inconditionnellement, lu ci-dessus par
    # os.environ[\"VF_SINGLE\"] — sans --file c'est \"\", donc 'not single' teste la chaine vide).
    cible_absente = (not single) and not os.path.isdir(agents_dir)
    files = sorted(glob.glob(os.path.join(agents_dir, \"*.md\")))
    files = [f for f in files if os.path.basename(f) not in NOT_AGENTS]
    if not files:
        # D-20 (Phase 42) : hors --hook, une cible ABSENTE sort desormais INDETERMINE (exit 3,
        # jeton CIBLE-ABSENTE) dans TOUS les modes, y compris sans --strict — --allow-empty
        # tolere aussi une cible absente, au meme titre qu'une cible vide (I2). Cette branche ne
        # touche PAS le contrat F13 ci-dessous (cible PRESENTE et vide, T21/T22/T23 inchanges).
        if cible_absente and not hook and not allow_empty:
            print(f\"[check-agents] ✗ INDETERMINE : {agents_dir} — CIBLE-ABSENTE, aucun verdict rendu (D-20)\")
            sys.exit(3)
        # Contrat de decouverte (F13, vacuous green) : en --strict, zero cible = zero verdict.
        # exit 3 = INDETERMINE, distinct de 0 = CONFORME. --allow-empty pour les cas legitimes.
        # Le code de sortie (3) est desormais INCONDITIONNEL — la traduction vers 0 sous --hook
        # est la responsabilite du shell (hook_exit, hors de ce bloc Python) : seul l'AFFICHAGE
        # reste conditionne a 'not hook' (le silence de flux, lui, reste un contrat du shell).
        # Chargement PARESSEUX (D-01/D-03) : une cible vide ne lit JAMAIS le manifeste.
        if strict and not allow_empty:
            if not hook:
                print(f\"[check-agents] ✗ INDETERMINE : aucun agent dans {agents_dir} — cible absente ou vide, aucun verdict rendu (--allow-empty pour tolerer)\")
            sys.exit(3)
        if not hook:
            print(f\"[check-agents] aucun agent dans {agents_dir} — rien a verifier\")
        sys.exit(0)
    charger_referentiel()
    for f in files:
        try:
            ftext = open(f, encoding=\"utf-8-sig\").read()
        except OSError as e:
            errors.append(f\"{os.path.basename(f)} : illisible ({e})\")
            continue
        # --third-party-prefix : un FICHIER dont le name matche n'est plus linte pour la
        # charte VibeFlow (ce n'est pas notre agent) — compte dans le resume, jamais un skip muet.
        dname = agent_display_name(f, ftext)
        matched_prefix = next((p for p in third_party_prefixes if p and dname.startswith(p)), None)
        if matched_prefix:
            thirdparty_files_total += 1
            continue
        check_file(f)

n_err, n_warn = len(errors), len(warnings)

def rapport_manifeste_perime():
    \"\"\"Ligne de rapport de fraicheur (D-05) — ne contient JAMAIS ✗ (avertissement, pas un
    refus) ; imprimee des que perimees est non vide, hook ou pas.\"\"\"
    desc = \"; \".join(perimees)
    return (f\"[check-agents] ⚠ MANIFESTE-PERIME — {desc} — listes fermees retrogradees en \"
            \"avertissement (D-05) ; rafraichir check-agents-manifest.json : relire chaque \"
            \"source, comparer, re-dater\")

if hook:
    # Sous --hook, la ligne de fraicheur est imprimee des que perimees est non vide — MEME
    # sans aucun autre avertissement (jamais silence de message, D-05) — puis le flux --hook
    # existant (compte errors/warnings) suit inchange, et sort 0 comme aujourd'hui.
    if perimees:
        print(rapport_manifeste_perime())
    if n_err:
        print(f\"[check-agents] ✗ {n_err} agent(s) non conforme(s) :\")
        for e in errors:
            print(f\"  - {e}\")
        print(\"  Corriger le frontmatter puis relancer : bash .claude/scripts/check-agents.sh\")
    elif n_warn:
        # D-21 : le hook trouvait desormais un perimetre reel (D-18/D-19) sans jamais le dire —
        # faux vert silencieux. Une ligne compacte, jamais une enumeration (le mode reste minimal) ;
        # silence total inchange quand n_err == 0 ET n_warn == 0 (regime nominal, cf. T56/T16).
        print(f\"[check-agents] ⚠ {n_warn} avertissement(s) — detail : bash .claude/scripts/check-agents.sh\")
    sys.exit(0)

# Hors --hook, la ligne de fraicheur PRECEDE la liste des avertissements (D-05).
if perimees:
    print(rapport_manifeste_perime())
for w in warnings:
    print(f\"  ⚠ {w}\")
if thirdparty_files_total or thirdparty_entries_total:
    pfx_str = ','.join(third_party_prefixes) if third_party_prefixes else '—'
    print(f\"[check-agents] {thirdparty_files_total} fichier(s) agent tiers non linte(s) · {thirdparty_entries_total} entree(s) d'allowlist tierce(s) resolue(s) (prefixe(s) : {pfx_str})\")
if n_err:
    print(f\"[check-agents] ✗ {n_err} non-conformite(s) bloquante(s) :\")
    for e in errors:
        print(f\"  ✗ {e}\")
    if not (perimees and manifest_freshness_strict):
        sys.exit(1)
# D-04 (Phase 42) : l'INDETERMINE (exit 3) n'est rendu QUE sous --manifest-freshness=strict —
# la CI du depot, seule legitime a rafraichir le manifeste. Prime sur un eventuel rc 1 deja
# imprime ci-dessus (lecture litterale de FABR-02) ; la ligne '✓ agents conformes' n'est JAMAIS
# imprimee dans ce cas.
if perimees and manifest_freshness_strict:
    print(\"[check-agents] ✗ INDETERMINE — MANIFESTE-PERIME : aucun verdict rendu (D-04) — rafraichir check-agents-manifest.json puis relancer\")
    sys.exit(3)
print(f\"[check-agents] ✓ agents conformes (natif + charte VibeFlow){' · ' + str(n_warn) + ' warning(s)' if n_warn else ''}\")
sys.exit(0)
"
PY_RC=$?
hook_exit "$PY_RC"
