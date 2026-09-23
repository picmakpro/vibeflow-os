# Phase 42 : Fabrique — manifeste daté et invariants de doctrine du gate des agents - Recherche

**Recherché le :** 2026-09-23
**Domaine :** lint machine de frontmatter d'agents Claude Code (bash + Python embarqué), anti-péremption de listes de référence, invariants de doctrine multi-agents
**Confiance :** HIGH (les points durs — sémantique `omitClaudeMd`, set d'outils, mécanique de l'installeur, corpus réel, T76, baseline d'instructions — sont tous vérifiés sur pièce ou contre la doc officielle ; MEDIUM sur le nommage exact des CLI flags, laissé à la discrétion de Claude par le cadrage)

<user_constraints>
## User Constraints (from CONTEXT.md)

> Zones grises tranchées par Claude sur délégation explicite de Willy (AskUserQuestion session
> principale, 2026-09-23 : « tranche tout, tu as de quoi »). Aucune décision ci-dessous n'est un
> arbitrage humain direct.

### Locked Decisions

**Le manifeste daté**
- **D-01** : un fichier de données versionné à côté du gate (`plugin/conductor/scripts/`, format
  JSON, lisible par le Python déjà embarqué). Il porte les six listes (identifiants d'outils,
  champs de frontmatter connus, types d'agents natifs, modèles, modes de permission, niveaux
  d'effort) et, pour chaque liste, `verifie_le` (date ISO) et `source` (URL de la doc officielle
  lue). Le script ne garde AUCUNE copie de repli des listes. Reversibility : costly.
- **D-02** : validité de 30 jours, portée par le manifeste lui-même (`valide_jours: 30`), jamais
  par le script.
- **D-03** : un fichier manifeste absent ou illisible est un refus explicite (exit ≠ 0 avec
  diagnostic), jamais une liste vide qui laisserait tout passer.

**Ce que fait un manifeste périmé**
- **D-04** : l'INDÉTERMINÉ (exit 3) n'est rendu que là où l'on peut rafraîchir le manifeste
  (CI du dépôt, option explicite passée par les étapes CI). Chez un utilisateur (guard d'écriture,
  hook SessionStart), un manifeste périmé produit un avertissement, jamais un refus. Reversibility :
  reversible.
- **D-05** : un manifeste périmé ne peut plus refuser sur une liste fermée — « outil inconnu »,
  « champ inconnu », « type natif inconnu » sont rétrogradées en avertissement dans TOUS les
  contextes quand le manifeste est périmé.

**Les invariants — définitions retenues**
- **D-06** : I1 se lit sur le marqueur `Worker interne` dans `description:`. Corrélation vérifiée
  dans les deux sens.
- **D-07** : un « manager » au sens d'I6 = porteur d'un `Agent(...)` non vide ET non `vf-internal`.
  Écart assumé vs spec §4.
- **D-08** : un « juge » au sens d'I5 = `disallowedTools` qui retire `Write` et `Edit` ET aucun
  `Agent(...)`. Juges visés : `quality-gate-client`, `content-clarity-judge`,
  `growth-quality-judge`, `vf-design-judge`. Écart assumé vs spec §4. Recherche demandée : sémantique
  exacte d'`omitClaudeMd`.
- **D-09** : I2 et I3 réutilisent le monde fermé existant (`--resolve-agents=strict` +
  `--agent-registry-dir`) — aucun registre écrit à la main. N'activent qu'en monde fermé.
- **D-10** : la découverte récursive exclut explicitement ce qui n'est pas un agent (règle vérifiée
  par un cas de test).

**La mise en conformité du corpus**
- **D-11** : les invariants sont armés en erreur, corpus corrigé dans cette phase, pas de période
  d'avertissement. Violations mesurées le 2026-09-23 : I3 `vf-test-orchestrator` (mobile-test-team,
  dispatché par `vf-dev-manager`, sans `vf-internal`) ; I5 les 4 juges de D-08 ; I6
  `vf-business-manager`, `vf-content-manager`, `vf-growth-manager`, `vf-design-manager`, et
  `vf-test-orchestrator` si le correctif I3 le laisse porteur d'un `Agent(...)` (à trancher par le
  planificateur) ; I1/I2/I4/I7 : zéro violation.
- **D-12** : un commit par module touché, séparé des commits du gate, avec bump de PATCH du module
  (VERSION, CHANGELOG). `mobile-test-team`, `dev-orchestrator` et `design-orchestrator` sont de la
  polarité de Samuel : la PR le nomme relecteur de ces commits-là.
- **D-13** : le test qui verrouille une affirmation périmée est corrigé dans cette phase (candidat
  mesuré : T76 de `test-check-agents.sh`, à confirmer par la recherche).

**Ordre avec la PR #85**
- **D-14** : on planifie maintenant, on exécute depuis `main` après le merge de la #85 (précondition
  de la première vague).
- **D-15** : tout commit de la phase qui touche le gate, sa suite, `ci.yml` ou un hook porte le
  trailer `Gate-Touche:` (CLAUDE.md, G-2).

### Claude's Discretion
- Nom et emplacement exact du fichier manifeste, nom de l'option CI de fraîcheur.
- Découpage en plans et en vagues.
- Forme des messages de diagnostic, dans le respect du contrat de sortie existant (0 / 1 / 3,
  silence de code sous `--hook`, jamais silence de message).

### Deferred Ideas (OUT OF SCOPE)
- Promouvoir l'avertissement « `skills:` absent » en erreur : hors phase.
- Rafraîchissement automatique du manifeste (tâche planifiée qui ouvre une PR) : hors phase — cf.
  §« Source machine-lisible » ci-dessous, qui répond à la question préalable.
- Unification `vf-mcp-consumer` / `vf-mcp-tools` : Phase 43.
- I8 et le correctif des blueprints (PR #85, déjà écrite) : hors phase, précondition seulement.
- Le gate des skills, l'unification MCP, le hook central par rôle, tout §8 de la spec
  (`skills:`, `cacheTtl`, `maxTurns`, `color:`) : hors phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FABR-01 | Manifeste daté, source unique des listes ; absent = refus (D-01, D-03) | §Standard Stack, §Architecture Patterns — Pattern 1 ; schéma JSON proposé, mécanique d'installation vérifiée (glob `copy_module_scripts`) |
| FABR-02 | Fraîcheur : INDÉTERMINÉ en CI, avertissement chez l'utilisateur, jamais de refus sur liste fermée périmée (D-02, D-04, D-05) | §Architecture Patterns — Pattern 2 ; §Common Pitfalls (portée exacte de la rétrogradation) |
| FABR-03 | Invariants I1-I7, définitions D-06 à D-09, chacun avec un jumeau négatif (mutation prouvée rouge) | §Architecture Patterns — Pattern 3 (I1/I2/I3), Pattern 4 (I5/I6) ; §Code Examples ; corpus réel mesuré §Common Pitfalls |
| FABR-04 | Découverte récursive avec exclusions testées (D-10) | §Architecture Patterns — Pattern 5 ; fixture recommandée §Code Examples |
| FABR-05 | Corpus conforme sous `--strict` et `--resolve-agents=strict` (D-11, D-12, D-13) | §Common Pitfalls (T76 déjà corrigé, impact nul sur le ratchet d'instructions), §Validation Architecture |
</phase_requirements>

## Summary

Le gate `check-agents.sh` (708 lignes, Python embarqué) porte aujourd'hui trois listes fermées en
dur (`TOOL_NAMES`, `KNOWN`, `NATIVE_TYPES`) derrière des commentaires datés que rien ne fait
expirer. La recherche confirme le diagnostic de la spec sur le fond, mais **corrige deux de ses
mesures, déjà périmées au moment où le cadrage a eu lieu** : (1) des 6 identifiants d'outils
annoncés manquants, seuls 3 le sont réellement (`ListAgents`, `SendFeedback`, `SubagentHandback`) —
`BashOutput` a été renommé `TaskOutput` (déjà dans `TOOL_NAMES`) et `KillShell` est un alias
documenté de `TaskStop` (déjà dans `TOOL_NAMES`) ; `SlashCommand` n'apparaît dans aucune doc
officielle vérifiable et ne doit pas être ajouté. (2) Le test T76, candidat désigné par le cadrage
pour « verrouiller une affirmation périmée » sur la profondeur de dispatch, **a déjà été corrigé le
2026-09-17 par le hotfix v2.63.2** — cinq jours avant l'écriture de la spec source de cette phase. Il
asserte aujourd'hui la doctrine correcte (profondeur 3, `PÉRIMÉE`, descripteur verbatim) contre le
fichier réel `team-kernel.md`, et passe. **FABR-05/D-13 n'a donc aucune action à mener sur T76** —
seule reste la mise en conformité du corpus (I3/I5/I6).

Sur la sémantique d'`omitClaudeMd` : la doc officielle confirme que le champ omet précisément les
CLAUDE.md utilisateur/projet/local (rien d'autre — les `rules/*.md` de VibeFlow ne sont pas
mentionnées, donc a priori non affectées, cf. §Assumptions). Ce fait valide D-08 : les 4 juges visés
(`quality-gate-client`, `content-clarity-judge`, `growth-quality-judge`, `vf-design-judge`) jugent un
livrable contre une rubrique, pas contre les conventions du dépôt — `vf-reviewer`/`vf-auditer`, eux,
ont besoin du CLAUDE.md du projet (qui porte les gates G-1/G-2/G-3 et les conventions de commit
qu'ils vérifient) et sont correctement exclus par D-08.

Sur l'installeur : `copy_module_scripts()` ne copie aujourd'hui que `*.sh`/`*.mjs`/`*.js` (exécutables)
et `*.txt` (données) depuis `scripts/` d'un module — **un fichier `.json` n'est copié par AUCUN des
globs existants**. C'est exactement le défaut qui a fait disparaître `known-versions.txt` avant la
Phase 31 (même cause : glob non étendu). Sans extension du glob (`*.json` ajouté au même endroit,
même patron que le fix `.txt`), D-03 refuserait le gate sur **tout lab installé depuis le plugin** —
un défaut bloquant à traiter dans la même vague que la pose du manifeste.

Sur le corpus : les 9 fichiers mesurés en violation (D-11) ont été vérifiés un par un sur le disque
réel ; toutes les corrections identifiées sont des ajouts de **frontmatter pur** (une ligne
`vf-internal: true`, un token `SendMessage` dans une liste `tools:` existante, une ligne
`omitClaudeMd: true`) — **aucune ne touche le corps de l'agent**, donc **aucune n'augmente le compte
d'INSTRUCTIONS** du ratchet armé `check-instruction-budget.sh` (défini comme « body seul, hors
frontmatter YAML »). Le corpus peut donc être corrigé sans toucher
`.planning/instruction-budget-baselines.tsv` ni citer d'arbitrage G-1 pour cette raison précise —
un piège évité qu'il valait la peine de vérifier avant planification.

**Primary recommendation :** extraire les six listes vers un JSON manifeste daté co-localisé
(`plugin/conductor/scripts/check-agents-manifest.json`), étendre `copy_module_scripts()` pour le
copier, ajouter la fraîcheur en périphérie (une fonction de lecture + une comparaison de date, pas de
dépendance nouvelle — `json`/`datetime` sont stdlib), ajouter I1-I7 comme des passes supplémentaires
sur le même arbre déjà parcouru par le gate, étendre la découverte en `glob.glob(..., "**/*.md",
recursive=True)` avec l'exclusion déjà nommée, corriger les 9 frontmatters du corpus réel (patch par
module), et laisser T76 intact — il n'est pas le défaut que le cadrage croyait avoir mesuré.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Chargement + fraîcheur du manifeste | CLI / script (Python embarqué dans `check-agents.sh`) | — | Le manifeste est une donnée locale au dépôt/lab, lue à chaque invocation du gate ; aucun réseau, aucun service |
| Invariants I1-I7 | CLI / script (même processus que le lint existant) | — | Passes supplémentaires sur le même AST frontmatter déjà parsé — pas un nouveau composant |
| Résolution monde fermé (I2/I3) | CLI / script, activée uniquement sous `--resolve-agents=strict` | CI (seule légitime à activer ce mode, cf. en-tête du gate) | Le calcul (qui dispatche qui) exige l'univers complet des agents, que seule la CI connaît sans faux positifs cross-module |
| Copie du manifeste vers un lab installé | Installeur (`plugin/_internal/vibeflow-update.sh`, `copy_module_scripts()`) | — | Fichier de données au même titre que `known-versions.txt` — même mécanisme, même glob à étendre |
| Fraîcheur différenciée CI / utilisateur | CI (`.github/workflows/ci.yml`) pour le mode strict ; hook `SessionStart`/`guard-agent-write.sh` pour le mode avertissement | — | Seule la CI a la légitimité de rafraîchir le manifeste (D-04) ; l'utilisateur reçoit un signal, jamais un blocage |
| Mise en conformité du corpus (frontmatter) | Fichiers `.md` sous `plugin/*/agents/` (données statiques versionnées) | — | Pur contenu déclaratif, aucune logique |

## Standard Stack

Cette phase n'introduit **aucune dépendance externe**. Le gate est un script bash qui invoque un bloc
Python embarqué (`python3 -c "..."`, repli `python`) ; toutes les capacités requises — parsing JSON,
arithmétique de date ISO — sont couvertes par la bibliothèque standard.

### Core
| Outil | Version | Rôle | Pourquoi standard |
|-------|---------|------|--------------------|
| `json` (stdlib Python) | 3.x (toute version supportée) | Parser le manifeste JSON | Déjà disponible partout où `check-agents.sh` tourne (le script exige déjà python3/python) ; aucune dépendance à ajouter |
| `datetime.date.fromisoformat` (stdlib) | Python ≥ 3.7 | Calculer l'âge du manifeste (`aujourd'hui - verifie_le`) contre `valide_jours` | Stdlib, ISO 8601 natif, cohérent avec le format `verifie_le` déjà choisi (D-01) |
| bash `set -uo pipefail` + glob | — | Découverte de fichiers, orchestration | Patron déjà utilisé par 100 % des gates du dépôt |

### Supporting
Aucune — le manifeste est un fichier de données statique, pas un service, pas un package.

### Alternatives Considered
| Au lieu de | Pourrait utiliser | Compromis |
|------------|--------------------|-----------|
| JSON stdlib | YAML (`pyyaml`) | Rejeté par D-01 lui-même (« format JSON, lisible par le Python DÉJÀ EMBARQUÉ ») — `pyyaml` n'est pas garanti installé sur un poste utilisateur, casserait le contrat zéro-dépendance du gate |
| Un 7ᵉ champ `source` unique pour tout le manifeste | Un `source` par liste (retenu) | D-01 exige un couple `verifie_le`/`source` PAR LISTE — un rafraîchissement partiel (une seule doc officielle a bougé) doit rester vérifiable liste par liste, pas en bloc |

**Installation :** aucune — fichier de données versionné dans le dépôt, aucune commande `npm
install`/`pip install`.

## Package Legitimacy Audit

**Non applicable.** Cette phase n'installe aucun package externe (npm, PyPI, ou autre) — elle ajoute
un fichier de données JSON versionné et des passes de lint supplémentaires dans un script bash/Python
déjà présent dans le dépôt. Le protocole de vérification de légitimité des paquets n'a donc aucune
cible.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────┐
                    │ plugin/conductor/scripts/    │
                    │ check-agents-manifest.json   │  ← D-01 : 6 listes datées + source
                    │ (co-localisé, versionné)      │
                    └──────────────┬────────────────┘
                                   │ lu à CHAQUE invocation
                                   ▼
   agents .md   ──▶   ┌─────────────────────────────────────────────┐
   (découverte        │ check-agents.sh (bash → python3 embarqué)    │
   récursive, D-10)   │                                               │
                       │  1. Charge le manifeste (D-03 : absent/     │
                       │     illisible → refus explicite)             │
                       │  2. Calcule la fraîcheur (D-02 : âge vs      │
                       │     valide_jours) → frais | périmé           │
                       │  3. Lint frontmatter EXISTANT (name,         │
                       │     description, model, memory, effort,     │
                       │     tools/disallowedTools tokenisés)         │
                       │     — utilise les listes du manifeste        │
                       │     (outils/champs/types/modèles/modes/      │
                       │     efforts) au lieu des sets en dur          │
                       │  4. Invariants I1-I7 (nouvelles passes,       │
                       │     D-06 à D-10) — voir Patterns 3/4/5        │
                       │  5. Si manifeste périmé : rétrograde          │
                       │     « outil/champ/type inconnu » en           │
                       │     avertissement PARTOUT (D-05) ; rend       │
                       │     INDÉTERMINÉ (exit 3) SEULEMENT si          │
                       │     --manifest-freshness=strict (CI) (D-04)   │
                       └───────────────┬───────────────────────────────┘
                                       │
                     ┌─────────────────┼──────────────────────┐
                     ▼                 ▼                      ▼
         guard-agent-write.sh   hook SessionStart        CI (3 étapes
         (--file --strict,      (--hook, silence de      check-agents +
         AUCUN --manifest-      code sous manifeste       1 étape monde
         freshness=strict       périmé — D-04)             fermé, D-04
         → jamais indéterminé)                             passe strict)
```

### Recommended Project Structure
```
plugin/conductor/scripts/
├── check-agents.sh              # existant, modifié : charge le manifeste, ajoute I1-I7
├── check-agents-manifest.json   # NOUVEAU (D-01) — nom proposé, Claude's Discretion
└── tests/
    └── test-check-agents.sh     # existant, étendu : cas manifeste absent/illisible/périmé,
                                  # I1-I7 (positif + mutation), découverte récursive + exclusion
```

### Pattern 1 : chargement fail-closed du manifeste (D-01, D-03)
**What :** avant tout lint, le script tente de lire et parser le JSON. Un fichier absent, illisible,
ou dont le JSON ne parse pas → diagnostic explicite + le même contrat de refus que la cible vide actuelle
(pas un `sys.exit(3)` réutilisé tel quel : D-03 dit *refus*, donc un comportement d'ERREUR (rc=1),
distinct de l'INDÉTERMINÉ de fraîcheur qui, lui, est réservé à D-04/D-05). Aucune liste de repli
n'est gardée en dur dans le script — le lint entier dépend du manifeste.
**When to use :** au tout début du bloc Python, avant `check_file()`.
**Example :**
```python
# Source : patron D-01/D-03, calqué sur vf_manifest_valid() de vibeflow-update.sh (refus global,
# jamais un skip ligne à ligne) et sur le contrat F13 déjà en vigueur dans ce script (cible vide
# en --strict = exit 3, jamais un vert silencieux).
MANIFEST_PATH = os.path.join(os.path.dirname(agents_dir if False else __file__), "..", "check-agents-manifest.json")
# (chemin réel résolu relativement au script, pas au cwd — cf. Common Pitfalls)
try:
    with open(manifest_path, encoding="utf-8") as fh:
        manifest = json.load(fh)
except (OSError, json.JSONDecodeError) as e:
    print(f"[check-agents] ✗ manifeste illisible ({manifest_path}: {e}) — AUCUN verdict rendu (D-03)")
    sys.exit(1)
```

### Pattern 2 : fraîcheur différenciée CI / utilisateur (D-02, D-04, D-05)
**What :** l'âge du manifeste se calcule à partir de `verifie_le` (le plus ancien des six, ou un champ
top-level dédié — Claude's Discretion) comparé à `valide_jours`. Le RÉSULTAT (frais/périmé) module le
comportement de TROIS classes d'erreurs existantes (« outil hors du set connu », « champ inconnu »,
« type natif non résolu ») — jamais les autres (name/description/model/memory/effort restent
inchangés, ils ne dépendent pas du manifeste... sauf `model`/`memory`/`effort` qui, eux, LISENT
aussi le manifeste pour `MODELS`/`MEMORY`/`EFFORT` — cf. Common Pitfalls, portée exacte à trancher
au plan).
**When to use :** une fonction pure `manifest_perime(manifest) -> bool`, appelée une fois, dont le
résultat conditionne `lint_tool_field` et le check de `KNOWN`/`NATIVE_TYPES`.
**Example :**
```python
# Source : D-02 (valide_jours porté par le manifeste), calcule sur date ISO stdlib — zéro dépendance.
from datetime import date
def manifest_perime(manifest):
    plus_ancien = min(date.fromisoformat(l["verifie_le"]) for l in manifest["listes"].values())
    age = (date.today() - plus_ancien).days
    return age > manifest.get("valide_jours", 30)

# D-04/D-05 : la rétrogradation ne s'applique QUE si le manifeste est périmé. Le mode
# --manifest-freshness=strict (nom proposé, Claude's Discretion — calqué sur le patron
# --resolve-agents=lenient|strict déjà en place) est la SEULE voie vers exit 3 ; le hook et
# guard-agent-write.sh ne le passent JAMAIS.
perime = manifest_perime(manifest)
if perime and freshness_strict:
    print("[check-agents] ✗ INDÉTERMINÉ : manifeste périmé — rafraîchir avant de rendre un verdict (D-04)")
    sys.exit(3)
```

### Pattern 3 : invariants I1/I2/I3 — corrélation `vf-internal` et monde fermé (D-06, D-07, D-09)
**What :** I1 est LOCAL à chaque fichier (pas besoin du monde fermé) : `vf-internal: true` ⟺ la
sous-chaîne `Worker interne` apparaît dans `description:`. I2/I3 exigent l'univers complet des
agents — ils ne s'activent QUE sous `--resolve-agents=strict` (D-09), exactement comme la résolution
de noms d'agent existante. Le script construit déjà, pour cette résolution, la fonction
`resolve_agent_name()` — I2/I3 réutilisent la MÊME collecte de fichiers (agents_dir + registry_dirs)
mais construisent en plus une **carte inversée** : pour chaque fichier manager (Agent(...) non vide),
quels noms sont dispatchés → recoupée avec le flag `vf-internal` de CHAQUE cible résolue.
**When to use :** une passe après le lint fichier-par-fichier, uniquement quand
`resolve_agents_strict` est vrai.
**Example :**
```python
# Source : D-09 — réutilise EXACTEMENT resolve_agent_name()/registry_dirs déjà présents (ligne 399
# de check-agents.sh), pas un second mécanisme de résolution.
dispatched_by = {}  # nom résolu -> [fichiers manager qui le dispatchent]
for f in all_files_in_closed_world:  # agents_dir + chaque --agent-registry-dir
    fm = parse_frontmatter(open(f).read())
    fmlines = frontmatter_lines(open(f).read())
    mode, raw = extract_raw_field(fmlines, "tools")
    tokens, depth = tokenize_field(mode, raw) if mode else ([], 0)
    for tok in tokens:
        name, agent_names = analyze_token(tok, "tools", os.path.basename(f))
        if name in AGENT_TOOL_NAMES and agent_names:
            for a in agent_names:
                verdict = resolve_agent_name(a, agents_dir, registry_dirs, third_party_prefixes)
                if verdict == "resolved":
                    dispatched_by.setdefault(a, []).append(os.path.basename(f))

for f in all_files_in_closed_world:
    fm = parse_frontmatter(open(f).read())
    name = fm.get("name") or os.path.basename(f)[:-3]
    is_internal = fm.get("vf-internal") == "true"
    is_dispatched = name in dispatched_by
    if is_internal and not is_dispatched:
        errors.append(f"{name} : I2 — worker vf-internal orphelin, aucun manager connu ne le dispatche")
    if is_dispatched and not is_internal:
        errors.append(f"{name} : I3 — dispatché par {dispatched_by[name]} sans vf-internal (worker exposé par erreur)")
```

### Pattern 4 : invariants I5/I6 — juges et managers (D-07, D-08)
**What :** classification PUREMENT structurelle, sur le frontmatter déjà tokenisé — aucune analyse de
prose.
**Example :**
```python
# Source : D-07 (manager = Agent(...) non vide ET non vf-internal), D-08 (juge = disallowedTools
# retire Write ET Edit ET aucun Agent(...))
disallowed_tokens = bare_tokens(fmlines, "disallowedTools")
tools_tokens = bare_tokens(fmlines, "tools")
has_nonempty_agent = any(
    analyze_token(t, "tools", base)[0] in AGENT_TOOL_NAMES and analyze_token(t, "tools", base)[1]
    for t in tokenize_field(*extract_raw_field(fmlines, "tools"))[0]
) if mode_tools else False

is_manager = has_nonempty_agent and fm.get("vf-internal") != "true"       # D-07
if is_manager and "SendMessage" not in tools_tokens:
    errors.append(f"{base} : I6 — manager sans SendMessage (pas de vue sur ses pairs)")

is_judge = ("Write" in disallowed_tokens and "Edit" in disallowed_tokens
            and not has_nonempty_agent)                                    # D-08
if is_judge and fm.get("omitClaudeMd") != "true":
    errors.append(f"{base} : I5 — juge sans omitClaudeMd: true (regard qui charge toute la doctrine)")
```

### Pattern 5 : découverte récursive avec exclusions (D-10)
**What :** remplacer le glob à un niveau par un glob récursif, en conservant `NOT_AGENTS` ET en
excluant tout chemin qui contient un composant `-references` ou `_reference` (patron déjà cité en
commentaire dans `guard-agent-write.sh` : « les sous-dossiers `*-references/` ne matchent pas »).
**Example :**
```python
# AVANT (ligne 650) :
files = sorted(glob.glob(os.path.join(agents_dir, "*.md")))
# APRÈS (D-10, exclusion testée) :
files = sorted(glob.glob(os.path.join(agents_dir, "**", "*.md"), recursive=True))
files = [f for f in files
         if os.path.basename(f) not in NOT_AGENTS
         and not any(seg.endswith("-references") or seg == "_reference"
                     for seg in os.path.relpath(f, agents_dir).split(os.sep))]
```

### Anti-Patterns to Avoid
- **Garder une copie de repli des listes « au cas où le manifeste est corrompu » :** exactement ce
  que D-01 interdit (« le script ne garde AUCUNE copie de repli ») — une copie de repli est le
  mécanisme même qui a produit la péremption silencieuse d'origine.
- **Faire dépendre la fraîcheur d'une SEULE date par liste sans agrégation claire :** si chaque liste
  a son propre `verifie_le`, le calcul de péremption globale doit être explicite (le plus ancien) et
  documenté — sinon deux lectures du même manifeste peuvent diverger sur « est-il périmé ? ».
- **Étendre `NATIVE_TYPES` avec un type non re-vérifié par une seconde source :** un seul WebFetch a
  mentionné un type natif `claude` (catch-all) non confirmé par la page `tools-reference` ni par une
  seconde lecture — ne PAS l'ajouter au manifeste sans revérification (cf. Assumptions Log A3).

## Don't Hand-Roll

| Problème | Ne pas construire | Utiliser à la place | Pourquoi |
|----------|---------------------|----------------------|----------|
| Résolution de noms d'agent en monde fermé (I2/I3) | Un second mécanisme de résolution parallèle à celui des allowlists `Agent(...)` | `resolve_agent_name()` existant (ligne 399), déjà appelé pour le lint des allowlists | Deux mécanismes de résolution qui peuvent diverger = exactement le défaut §1.2 de la spec (« deux conventions MCP concurrentes ») reproduit ailleurs |
| Parsing du frontmatter YAML | Un import `pyyaml` ou un second parseur | `parse_frontmatter()`/`frontmatter_lines()`/`extract_raw_field()` existants | Le tokenizer actuel gère déjà les cas retors (continuation indentée, guillemets, listes YAML, allowlists à profondeur de parenthèses) — un second parseur réintroduirait leurs bugs déjà corrigés un par un (historique des commentaires du fichier) |
| Calcul de date/péremption | Une lib tierce (`dateutil`, etc.) | `datetime.date.fromisoformat` (stdlib) | Le format `verifie_le` est déjà choisi en ISO 8601 — stdlib suffit, zéro dépendance nouvelle dans un script qui n'en a aujourd'hui aucune |
| Copie du fichier manifeste vers les labs installés | Un nouveau mécanisme de copie ad hoc | Étendre le glob existant de `copy_module_scripts()` (patron déjà posé pour `*.txt`, Phase 31) | Le patron est déjà écrit, testé, et documenté en commentaire (« Site #3 (31-03) ») — dupliquer la logique de copie créerait une DEUXIÈME voie de pose de fichiers de données, source de divergence |

**Key insight :** cette phase ne fait QUE déplacer des données vers un fichier externe et ajouter des
passes de lint sur une structure déjà parsée par le script existant — toute tentation de réécrire un
mécanisme (parsing, résolution, copie) en parallèle du mécanisme déjà en place reproduit exactement
le défaut structurel (deux vérités, une qui pourrit) que la phase existe pour éliminer.

## Common Pitfalls

### Pitfall 1 : le diagnostic de la spec source est LUI-MÊME déjà périmé sur 2 points
**What goes wrong :** planifier la correction des 6 identifiants d'outils annoncés manquants
(`ListAgents`, `SendFeedback`, `SubagentHandback`, `BashOutput`, `KillShell`, `SlashCommand`) et la
correction de T76 comme si les deux étaient encore des défauts ouverts.
**Why it happens :** la spec source a été écrite le 2026-09-22. Entre-temps (et même avant, pour
T76), deux faits ont changé sans que la spec le sache : (a) `BashOutput` a été renommé `TaskOutput`
et `KillShell` documenté comme alias déprécié de `TaskStop` — les DEUX noms actuels sont déjà dans
`TOOL_NAMES` (le script embarqué ligne 196-204 les porte déjà) ; `SlashCommand` n'apparaît dans
AUCUNE des deux pages officielles vérifiées (`tools-reference`, `sub-agents`) — WebSearch seul
(non officiel) le mentionne sans source vérifiable, donc `[ASSUMED]` non retenu ; (b) le hotfix
v2.63.2 (2026-09-17, commit `a1ba3a5`/`adab2aa`/`23868d7`, cf. STATE.md) a DÉJÀ corrigé
`team-kernel.md` et T76 pour asserter la doctrine correcte (« profondeur 3 », marqueur `PÉRIMÉE`,
descripteur verbatim) — vérifié en relisant le fichier réel `plugin/conductor/references/team-kernel.md`
lignes 37-122 : les 13 littéraux que T76 exige (`t76_detect`, lignes 1415-1426 du test) y sont TOUS
présents.
**How to avoid :** ne planifier QUE l'ajout de `ListAgents`, `SendFeedback`, `SubagentHandback` au
manifeste (3 identifiants réellement manquants, vérifiés sur `tools-reference`) ; ne PAS toucher
T76 ni `team-kernel.md` pour FABR-05/D-13 — vérifier au premier plan que T76 passe déjà (`bash
plugin/conductor/scripts/tests/test-check-agents.sh` en isolant T76) avant d'y consacrer une tâche.
**Warning signs :** si un plan contient une tâche « corriger T76 » ou « ajouter BashOutput/KillShell/
SlashCommand au manifeste », c'est le signal que la relecture de la spec source n'a pas recoupé
l'état réel du disque.

### Pitfall 2 : un manifeste `.json` non copié par l'installeur rend D-03 catastrophique
**What goes wrong :** poser `check-agents-manifest.json` à côté du script sans étendre
`copy_module_scripts()` — l'installeur ne le copie JAMAIS chez un utilisateur (`vibeflow-update.sh`,
fonction `copy_module_scripts()`, lignes 1965-2028), et D-03 (manifeste absent = refus) transforme
CE silence en refus total du gate sur TOUT lab installé depuis le plugin (y compris via le job CI
`lab-frais`/`lab-frais-arme`, qui échouerait immédiatement).
**Why it happens :** la boucle actuelle ne copie que `*.sh`/`*.mjs`/`*.js` (mode `exec`) et `*.txt`
(données, sans `chmod +x`) — vérifié en lisant le corps de la fonction. Un `.json` ne matche AUCUN
des trois globs. C'est EXACTEMENT le défaut déjà vécu et corrigé une fois pour `known-versions.txt`
(commentaire du code : « Site #3 (31-03)... c'est exactement ce qui est arrivé à
`known-versions.txt` »).
**How to avoid :** ajouter une boucle `for f in "$module_dir/scripts/"*.json` (même patron que la
boucle `*.txt`, sans mode exec) dans `copy_module_scripts()`, DANS LA MÊME VAGUE que la pose du
manifeste — jamais dans un plan séparé qui pourrait s'exécuter d'abord.
**Warning signs :** le job CI `lab-frais-arme` (install réelle de `dev-orchestrator`, qui NE dépend
PAS de `conductor` directement mais partage l'installeur) et le job `lab-frais` (install de
`conductor`) sont les deux témoins qui rougiraient immédiatement si ce fix manque — les inclure
explicitement dans la checklist de vérification de phase.

### Pitfall 3 : la rétrogradation D-05 a une portée à trancher précisément
**What goes wrong :** rétrograder TOUTES les erreurs de lint quand le manifeste est périmé (y
compris `model invalide`, `memory invalide`, `effort invalide`) au lieu des SEULES trois nommées par
D-05 (« outil inconnu », « champ inconnu », « type natif inconnu »).
**Why it happens :** `MODELS`/`MEMORY`/`EFFORT`/`PERM` viennent AUSSI du manifeste selon D-01 (« il
porte les six listes... modèles, modes de permission, niveaux d'effort »). Un lecteur rapide peut
conclure que TOUT ce qui dépend du manifeste doit se rétrograder ensemble.
**How to avoid :** relire D-05 littéralement — seules trois classes sont nommées (« outil inconnu »,
« champ inconnu », « type natif inconnu »). `model`/`memory`/`effort` invalides restent des ERREURS
bloquantes MÊME sous manifeste périmé (un modèle inventé reste un modèle inventé, indépendamment de
la fraîcheur de la doc). Documenter ce choix explicitement dans le plan — c'est une lecture stricte
du texte de la décision, pas une extrapolation.

### Pitfall 4 : confondre le « manifeste » du gate avec le « manifeste » de l'installeur
**What goes wrong :** nommer le nouveau fichier `manifest.json` sans préfixe distinctif — collision
de VOCABULAIRE (pas de fichier) avec `scripts/.vibeflow-manifest-<mod>` (le manifeste d'INSTALLATION
que `vibeflow-update.sh` écrit pour chaque module, `vf_manifest_path()`), qui est un concept
complètement différent (liste des fichiers posés, pas des listes de référence du gate).
**How to avoid :** nommer le fichier `check-agents-manifest.json` (préfixé par le nom du gate,
patron déjà en place pour `known-versions.txt` co-localisé avec `audit-infra.sh`) — ou tout nom au
choix de Claude qui évite la sous-chaîne nue `manifest.json`. Documenter le choix dans le plan pour
qu'un futur lecteur ne cherche pas ce fichier via `vf_manifest_*`.

### Pitfall 5 : les corrections du corpus DOIVENT rester du frontmatter pur
**What goes wrong :** en corrigeant I5/I6, toucher au corps (description longue, section de prose)
d'un des 9 fichiers plutôt que la seule ligne de frontmatter requise — ce qui ferait grimper le
compte INSTRUCTIONS du ratchet armé (`check-instruction-budget.sh`, BUDG-01/02, armé depuis
2026-09-16) et déclencherait G-1 (`check-baseline-arbitrage.sh`), exigeant une citation d'arbitrage
dans le commit ET une mise à jour manuelle de `.planning/instruction-budget-baselines.tsv`.
**Why it happens :** la tentation d'« expliquer » le nouveau champ dans la description (par exemple
ajouter une phrase narrative sur `SendMessage` dans le corps) au lieu de se limiter à l'ajout
mécanique du champ.
**How to avoid :** vérifié sur mesure — les 3 corrections nécessaires (I3 : `vf-internal: true` +
marqueur `Worker interne` DANS `description:` déjà comptée comme frontmatter, pas le corps ; I5 :
`omitClaudeMd: true`, une ligne ; I6 : ajouter le token `SendMessage` à une ligne `tools:` déjà
existante) sont TOUTES des lignes de frontmatter. Le body (après le second `---`) reste inchangé sur
les 9 fichiers. Vérifier avec `bash plugin/conductor/scripts/check-instruction-budget.sh` avant/après
sur les fichiers touchés : la colonne INSTR ne doit PAS bouger (elle est définie « body seul, hors
frontmatter YAML »).
**Warning signs :** un `git diff` sur un des 9 fichiers qui touche une ligne APRÈS le second `---`
est le signal qu'un plan a dérivé du frontmatter pur.

### Pitfall 6 : la portée exacte du trailer `Gate-Touche:` (G-2)
**What goes wrong :** omettre le trailer sur un commit qui touche `check-agents.sh` ou `ci.yml`, ou
au contraire l'ajouter inutilement sur un commit qui touche `plugin/conductor/hooks/hooks.json` ou
`team-kernel.md` en pensant que ces fichiers sont couverts.
**Why it happens :** `check-gate-touche.sh` définit EXACTEMENT 5 classes (lues sur pièce, lignes
20-45 du script) : (1) `plugin/conductor/scripts/check-*.sh` à un seul niveau — couvre
`check-agents.sh` ; (2) `scripts/check-*.sh` racine — hors périmètre de cette phase ; (3) leurs
suites `*/tests/test-*.sh` — couvre `test-check-agents.sh` ; (4) `.github/workflows/ci.yml` exact —
couvre l'ajout de l'option de fraîcheur aux 3 étapes `check-agents` ; (5) tout chemin commençant par
`scripts/hooks/` — **`plugin/conductor/hooks/hooks.json` N'EST PAS sous `scripts/hooks/`, donc N'EST
PAS couvert**, même si D-15 le nomme comme un « hook » au sens large.
**How to avoid :** table de vérité précise pour le plan (voir tableau ci-dessous). Ne pas ajouter le
trailer par réflexe sur `hooks.json` ou `team-kernel.md` (ni sur `guard-agent-write.sh`, qui ne
matche PAS non plus le motif — il ne commence pas par `check-`, borne nommée explicitement dans
l'en-tête du gate G-2 comme un angle mort assumé, pas un oubli).

| Chemin touché par cette phase | Couvert par G-2 ? | Classe |
|---|---|---|
| `plugin/conductor/scripts/check-agents.sh` | OUI | 1 |
| `plugin/conductor/scripts/check-agents-manifest.json` (nouveau) | NON (pas `check-*.sh`) | — |
| `plugin/conductor/scripts/tests/test-check-agents.sh` | OUI | 3 |
| `.github/workflows/ci.yml` | OUI | 4 |
| `plugin/conductor/hooks/hooks.json` (SI touché pour un flag CLI) | NON | — |
| `plugin/conductor/references/team-kernel.md` (SI touché, probablement non nécessaire — Pitfall 1) | NON | — |
| `plugin/conductor/scripts/guard-agent-write.sh` (SI touché — a priori non nécessaire, il shell-out déjà) | NON (ne commence pas par `check-`) | borne nommée |
| `plugin/*/agents/*.md` (corpus, 9 fichiers) | NON | — |

## Code Examples

### Schéma JSON proposé du manifeste (D-01)
```json
{
  "valide_jours": 30,
  "listes": {
    "outils": {
      "verifie_le": "2026-09-23",
      "source": "https://code.claude.com/docs/en/tools-reference",
      "valeurs": ["Agent", "Artifact", "AskUserQuestion", "Bash", "CronCreate", "CronDelete",
        "CronList", "Edit", "EndConversation", "EnterPlanMode", "EnterWorktree", "ExitPlanMode",
        "ExitWorktree", "Glob", "Grep", "ListAgents", "ListMcpResourcesTool", "LSP", "Monitor",
        "NotebookEdit", "PowerShell", "PushNotification", "Read", "ReadMcpResourceTool",
        "RemoteTrigger", "ReportFindings", "ScheduleWakeup", "SendFeedback", "SendMessage",
        "SendUserFile", "ShareOnboardingGuide", "Skill", "SubagentHandback", "TaskCreate",
        "TaskGet", "TaskList", "TaskOutput", "TaskStop", "TaskUpdate", "TodoWrite", "ToolSearch",
        "WaitForMcpServers", "WebFetch", "WebSearch", "Workflow", "Write"]
    },
    "champs_frontmatter": {
      "verifie_le": "2026-09-23",
      "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["name", "description", "tools", "disallowedTools", "model", "permissionMode",
        "maxTurns", "skills", "mcpServers", "hooks", "memory", "background", "omitClaudeMd",
        "effort", "isolation", "color", "initialPrompt", "experimental"]
    },
    "types_natifs": {
      "verifie_le": "2026-09-23",
      "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["explore", "plan", "general-purpose", "statusline-setup", "claude-code-guide", "fork"]
    },
    "modeles": {
      "verifie_le": "2026-09-23",
      "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["sonnet", "opus", "haiku", "fable", "inherit"]
    },
    "modes_permission": {
      "verifie_le": "2026-09-23",
      "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["default", "acceptEdits", "auto", "dontAsk", "bypassPermissions", "plan", "manual"]
    },
    "niveaux_effort": {
      "verifie_le": "2026-09-23",
      "source": "https://code.claude.com/docs/en/sub-agents",
      "valeurs": ["low", "medium", "high", "xhigh", "max"]
    }
  }
}
```
Note : les champs VibeFlow (`vf-internal`, `vf-mcp-consumer`, `vf-mcp-tools`, `vf-requires`) restent
codés en dur dans le script — ce sont des conventions du dépôt, pas des identifiants dont une doc
Anthropic externe peut faire péremption. D-01 borne explicitement le manifeste aux SIX listes
d'origine native.

### Fixture de test recommandée pour D-10 (découverte récursive + exclusion)
```bash
# Source : patron D-10, à ajouter dans test-check-agents.sh — AUCUNE sous-arborescence n'existe
# aujourd'hui sous plugin/*/agents/ (vérifié par find), donc la garde ne peut être prouvée QUE par
# fixture synthétique, jamais sur l'arbre réel (contrairement à T75/T76).
MUT_AG="$WORK/t-recursive"; mkdir -p "$MUT_AG/sub-references"
cp "$SK_VALID_AGENT" "$MUT_AG/valid.md"
echo "pas un agent" > "$MUT_AG/sub-references/lead-knowledge.md"
OUT="$(bash "$CHECK" --agents-dir="$MUT_AG" --skills-dir="$SK" 2>&1)"; RC=$?
# attendu : rc=0 (valid.md conforme), AUCUNE mention de sub-references/lead-knowledge.md dans $OUT
```

### Test de non-impact du ratchet d'instructions (Pitfall 5, à intégrer au plan de vérification)
```bash
# Avant modification :
bash plugin/conductor/scripts/check-instruction-budget.sh 2>&1 | grep -E "vf-business-manager|vf-content-manager|vf-growth-manager|vf-design-manager|quality-gate-client|content-clarity-judge|growth-quality-judge|vf-design-judge|vf-test-orchestrator" > /tmp/before.txt
# ... corrections frontmatter des 9 fichiers ...
# Après modification :
bash plugin/conductor/scripts/check-instruction-budget.sh 2>&1 | grep -E "même liste" > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt   # attendu : SEULE la colonne LIGNES bouge (+1 par fichier tout au plus), INSTR identique
```

## State of the Art

| Ancienne approche | Approche actuelle | Quand ça a changé | Impact |
|--------------------|---------------------|----------------------|--------|
| Identifiant d'outil `BashOutput` | `TaskOutput` (BashOutput déprécié/renommé) | Documenté sur `code.claude.com/docs/en/agent-sdk/python`, daté non précisé mais visible dans la doc actuelle (2026-09-23) | Le manifeste doit porter `TaskOutput`, pas `BashOutput` — déjà le cas dans le `TOOL_NAMES` actuel |
| `KillShell`/`KillBash` | Alias dépréciés de `TaskStop` | Idem | Pas d'ajout requis — `TaskStop` déjà présent |
| Listes de référence en dur derrière des commentaires datés | Manifeste JSON externe avec `verifie_le`/`source` par liste | Cette phase | Anti-rot structurel : la péremption devient DÉTECTABLE au lieu de silencieuse |
| Découverte des agents à un seul niveau (`glob(*.md)`) | Découverte récursive avec exclusions testées | Cette phase (D-10) | Un sous-dossier accidentel ne rend plus le gate vert sur un corpus partiellement invisible |

**Deprecated/outdated :**
- `BashOutput` en tant qu'identifiant de premier rang : remplacé par `TaskOutput` (le nom reste
  utilisable comme alias historique dans certains contextes SDK, mais la doc actuelle documente
  `TaskOutput` comme le nom courant — `TaskOutput` est déjà dans `TOOL_NAMES`).
- `KillShell`/`KillBash` : alias de `TaskStop`, déjà couvert.

## Assumptions Log

| # | Claim | Section | Risque si faux |
|---|-------|---------|------------------|
| A1 | `SlashCommand` n'est PAS un identifiant d'outil réel documenté — écarté du manifeste | Pitfall 1, Code Examples (schéma JSON) | Faible : si un futur `SlashCommand` existe réellement et n'est pas ajouté, il produit un simple AVERTISSEMENT (jamais bloquant hors `--strict`) le temps du prochain rafraîchissement du manifeste — c'est exactement le filet que D-01/D-02 posent |
| A2 | `omitClaudeMd: true` n'affecte PAS le chargement des `rules/*.md` de VibeFlow (mécanisme distinct des fichiers CLAUDE.md) | Summary, Pattern 4 | Moyen si faux : si `omitClaudeMd` supprimait AUSSI l'injection des `rules/*.md`, cela pourrait affecter d'autres agents non concernés par cette phase qui déclareraient ce champ plus tard — sans conséquence sur LES 4 JUGES visés ici (qui n'ont besoin d'aucune rule projet pour juger un livrable contre une rubrique) |
| A3 | Un éventuel type natif `claude` (catch-all générique, mentionné par une seule requête WebFetch, non confirmé par une seconde source ni par la page `tools-reference`) n'est PAS ajouté à `NATIVE_TYPES` | Anti-Patterns (Pattern 5) | Faible : un agent qui déclarerait `Agent(claude)` resterait en AVERTISSEMENT « non résolu » (jamais bloquant hors `--resolve-agents=strict`) — comportement déjà documenté comme le régime voulu pour la rouille de cette liste |
| A4 | Le calcul de péremption du manifeste utilise le PLUS ANCIEN `verifie_le` parmi les six listes (pas une moyenne, pas un champ top-level séparé) | Pattern 2 | Faible : le choix inverse (le plus récent, ou un champ dédié) reste également conforme à D-02 — c'est un détail d'implémentation, à trancher explicitement au plan, pas une divergence de doctrine |

**Si cette table est vide :** non applicable — 4 assomptions identifiées, toutes de risque faible à
moyen, aucune ne remet en cause une décision verrouillée de CONTEXT.md.

## Open Questions (RESOLVED)

1. **`vf-test-orchestrator` reste-t-il un « manager » au sens I6 après le correctif I3 ?** — RESOLVED : worker interne sans `SendMessage`, lecture littérale de D-07 (plan 42-02, tâche 1).
   - What we know : ajouter `vf-internal: true` + marqueur `Worker interne` résout I3 (dispatché par
     `vf-dev-manager`, désormais correctement marqué interne) ET, par la définition D-07 elle-même
     (« manager = Agent(...) non vide ET **non vf-internal** »), le sort AUTOMATIQUEMENT de la
     classification « manager » pour I6 — donc I6 ne s'applique plus à lui, sans ajouter
     `SendMessage`.
   - What's unclear : la CONTEXT.md D-11 dit explicitement « à trancher par le planificateur au vu
     du fichier » — laissant ouverte l'hypothèse alternative (garder `vf-test-orchestrator` NON
     `vf-internal` et lui ajouter `SendMessage` à la place).
   - Recommendation : appliquer la lecture littérale de D-07 — un seul champ ajouté
     (`vf-internal: true` + marqueur) résout SIMULTANÉMENT I2 (il est bien dispatché, donc pas
     orphelin), I3 (il est désormais marqué interne) et exempte de I6 (il n'est plus « manager » au
     sens D-07). C'est la correction la plus petite et la plus cohérente avec le patron déjà en place
     sur `vf-coder`/`vf-reviewer`/`vf-auditer` (tous trois managers-au-sens-large mais vf-internal,
     donc hors I6).

2. **`dev-orchestrator` a-t-il réellement besoin d'un commit de correctif de corpus ?** — RESOLVED : non, aucun `files_modified` dans ce module (constat consigné au plan 42-06).
   - What we know : D-12 nomme `dev-orchestrator` comme un des trois modules « de la polarité de
     Samuel » à faire relire. La recherche n'a trouvé AUCUNE violation I1-I7 sur les agents propres à
     `dev-orchestrator` (`vf-dev-manager` porte déjà `SendMessage` ; `vf-coder`/`vf-reviewer`/
     `vf-auditer` sont déjà `vf-internal`, donc hors I6 ; aucune violation I5 côté dev-orchestrator).
     Les seules mentions de `vf-test-orchestrator` dans les fichiers `dev-orchestrator` sont de la
     PROSE (descriptions, tables de routage) qui reste valide quel que soit le choix retenu en Q1.
   - What's unclear : si le planificateur choisit malgré tout de documenter le changement de statut
     de `vf-test-orchestrator` dans `mission-flow.md`/`head-governance.md` (cohérence narrative), ce
     serait un choix éditorial, pas une exigence du gate.
   - Recommendation : ne prévoir de commit `dev-orchestrator` QUE si un fichier de CE module doit
     changer concrètement (aucun trouvé à ce jour) — sinon, retirer `dev-orchestrator` de la liste des
     commits de patch prévus par D-12, tout en gardant Samuel nommé relecteur des commits
     `mobile-test-team`/`design-orchestrator` qui, eux, sont bien nécessaires.

3. **Nom exact de l'option CI de fraîcheur et du fichier manifeste.** — RESOLVED : `--manifest-freshness` et `check-agents-manifest.json` (plan 42-01).
   - What we know : Claude's Discretion explicite (CONTEXT.md). Le patron `--resolve-agents=lenient|
     strict` est déjà établi dans ce même script pour un besoin structurellement identique (un mode
     par défaut sûr, un mode strict réservé à la CI).
   - What's unclear : aucune contrainte technique ne force un nom précis.
   - Recommendation : `--manifest-freshness=lenient|strict` (défaut lenient) pour l'option CLI, et
     `check-agents-manifest.json` pour le fichier — les deux cohérents avec le vocabulaire déjà en
     place et évitant la collision avec `vf_manifest_*` (Pitfall 4).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `python3` | `check-agents.sh` (bloc embarqué, y compris le nouveau parsing JSON) | ✓ | — (déjà exigé par le script existant, repli `python`, détection stub WindowsApps déjà gérée ADR-054) | déjà géré par le script (`PYBIN` fallback) |
| `bash` | orchestration du gate, tests | ✓ | — | — |
| `git` (CI uniquement) | découverte des chemins modifiés pour `check-gate-touche.sh` | ✓ | — | — |
| Réseau / service externe | aucun | — | — | — (le manifeste est un fichier local, aucun appel réseau au runtime du gate) |

**Missing dependencies with no fallback :** aucune.
**Missing dependencies with fallback :** aucune — tout est déjà présent dans l'environnement du
dépôt et des labs installés.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suite bash maison, patron `test-*.sh` (pas de framework tiers — `ok`/`ko` + assertions `cmp`) |
| Config file | aucun — découverte par la CI via `find plugin scripts -type f -path '*/tests/test-*.sh'` |
| Quick run command | `bash plugin/conductor/scripts/tests/test-check-agents.sh` |
| Full suite command | boucle CI `.github/workflows/ci.yml` job `tests` (rejoue toutes les suites `test-*.sh` découvertes) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FABR-01 | manifeste absent/illisible → refus explicite (rc≠0), jamais une liste vide qui laisse tout passer | unit (mutation : renommer/corrompre le manifeste) | `bash plugin/conductor/scripts/tests/test-check-agents.sh` (nouveaux cas T77+) | ❌ Wave 0 |
| FABR-02 | manifeste périmé → avertissement hors CI, INDÉTERMINÉ (exit 3) sous `--manifest-freshness=strict` ; jamais de refus sur liste fermée périmée | unit (mutation : `verifie_le` reculé de 31 jours) | idem | ❌ Wave 0 |
| FABR-03 | I1-I7, chacun avec jumeau négatif (mutation prouvée rouge) sur fixtures ET, quand pertinent, sur l'arbre réel (patron T75/T76 : `cmp` avant/après) | unit + mutation | idem | ❌ Wave 0 (fixtures) + réutilise l'arbre réel existant pour la preuve de non-régression corpus |
| FABR-04 | découverte récursive + exclusion `-references`/fichiers non-agents, testée par fixture synthétique | unit (fixture, aucune donnée réelle disponible) | idem | ❌ Wave 0 — cf. Code Examples |
| FABR-05 | corpus réel conforme sous `--strict` ET `--resolve-agents=strict` (monde fermé, les 6 dossiers `plugin/*/agents`) | integration/CI | les 3 étapes CI `check-agents` existantes (`.github/workflows/ci.yml` ~l.256-320), rejouées localement avec les mêmes arguments | ✓ (étapes CI déjà présentes, à laisser inchangées dans leur logique — seul l'ajout de l'option de fraîcheur les modifie) |

### Sampling Rate
- **Per task commit :** `bash plugin/conductor/scripts/tests/test-check-agents.sh` (quick, < 5s
  mesuré sur 87 cas existants + nouveaux cas).
- **Per wave merge :** rejeu des 3 étapes CI `check-agents` en local (`--strict` par module,
  `--strict --file` sur les `AGENT.md`, `--strict --resolve-agents=strict` en monde fermé) +
  `bash plugin/conductor/scripts/check-instruction-budget.sh` (vérifier l'absence d'impact, Pitfall 5).
- **Phase gate :** full suite CI verte (`gates` + `tests` + `lab-frais` + `lab-frais-arme`) avant
  `/gsd-verify-work` — `lab-frais`/`lab-frais-arme` sont les témoins directs du Pitfall 2 (manifeste
  non copié par l'installeur).

### Wave 0 Gaps
- [ ] Nouveaux cas dans `plugin/conductor/scripts/tests/test-check-agents.sh` (numérotation à partir
  de T77 — dernier test existant : T76) : manifeste absent, manifeste illisible (JSON malformé),
  manifeste périmé + mode lenient (avertissement), manifeste périmé + mode strict (exit 3), I1 (positif
  + mutation dans les deux sens), I2 (worker orphelin), I3 (worker exposé — sur fixture ET sur
  `vf-test-orchestrator` réel PRÉ-correction pour prouver le rouge, puis POST-correction pour le vert),
  I5 (juge sans `omitClaudeMd`, sur les 4 juges réels), I6 (manager sans `SendMessage`, sur les 5
  managers réels), I7 déjà zéro violation (test de non-régression seul), découverte récursive +
  exclusion (fixture synthétique, cf. Code Examples).
- [ ] Extension de `copy_module_scripts()` dans `vibeflow-update.sh` : cas de test (probablement dans
  la suite d'installeur existante, à localiser au plan) prouvant qu'un `.json` sous
  `<module>/scripts/` est bien copié.
- [ ] Aucun framework à installer — la suite bash existante couvre déjà le patron requis.

*(Gaps ci-dessus seuls — le reste de l'infrastructure de test du gate est mature et réutilisable.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V1 Architecture | oui | fail-closed déjà établi comme doctrine du dépôt (D-03, cohérent avec `vf_manifest_valid()` de l'installeur et le contrat F13 déjà en place dans ce même gate) |
| V2 Authentication | non | aucune notion d'identité — script CLI local |
| V3 Session Management | non | sans objet |
| V4 Access Control | non | le gate ne contrôle pas d'accès, il linte du contenu déclaratif |
| V5 Input Validation | oui | le manifeste JSON est une entrée non fiable au même titre qu'un frontmatter d'agent : `json.load` dans un `try/except` explicite (jamais un `eval`/`exec` sur le contenu), aucune valeur du manifeste n'est interpolée dans une commande shell (le manifeste ne PRODUIT que des `set`/listes Python comparées, jamais exécutées) |
| V6 Cryptography | non | sans objet — pas de secret, pas de chiffrement |

### Known Threat Patterns for ce domaine

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|------------------------|
| Manifeste JSON malformé ou tronqué (accidentel ou par une PR malveillante) faisant passer le gate en vert à vide | Tampering / Denial of Service (du contrôle lui-même) | D-03 : refus explicite (rc≠0) sur JSON illisible, jamais un repli silencieux vers une liste vide — testé par mutation (Wave 0 gap) |
| Une entrée de liste du manifeste contenant un caractère de contrôle ou une séquence shell (ex. un `nom` d'outil forgé avec `; rm -rf`) | Injection | Aucune valeur du manifeste n'est jamais interpolée dans une commande `bash`/`subprocess` — toutes les comparaisons restent en mémoire Python (`in TOOL_NAMES_SET`), donc la classe d'attaque n'a pas de surface. À vérifier explicitement au plan (assertion négative : `grep` du futur code montre qu'aucune valeur issue du manifeste n'atteint `subprocess`/`os.system`) |
| Un manifeste marqué frais alors qu'il est en réalité obsolète (date `verifie_le` mensongère, forgée volontairement) | Repudiation / Tampering | Hors périmètre technique de cette phase — le gate ne PEUT PAS vérifier la véracité d'une date déclarée, seulement sa fraîcheur FORMELLE (patron déjà assumé par `check-gate-touche.sh` pour les trailers : « vérification de forme, jamais de véracité », cohérent avec la doctrine du dépôt) |

## Project Constraints (from CLAUDE.md)

Directives extraites de `./CLAUDE.md`, à respecter par le plan :

- **Gates G-1/G-2/G-3** : tout commit touchant `plugin/conductor/scripts/check-agents.sh`,
  `plugin/conductor/scripts/tests/test-check-agents.sh` ou `.github/workflows/ci.yml` porte un
  trailer `Gate-Touche: <chemin-ou-motif> — <raison ≥ 10 caractères non blancs>` (cf. table exacte
  au Pitfall 6). Aucun autre chemin de cette phase n'est concerné par ce trailer.
- **Densité (ADR-029)** : les 9 fichiers d'agents corrigés restent sous les seuils (avertissement dès
  251 lignes, blocage au-delà de 300) — non menacé (corrections d'1 ligne ou moins sur des fichiers
  entre 60 et 192 lignes).
- **Ratchet d'instructions (BUDG-01/02)** : armé depuis 2026-09-16 — les corrections de corpus DOIVENT
  rester en frontmatter pur (Pitfall 5), sinon exige une citation d'arbitrage ET une mise à jour de
  `.planning/instruction-budget-baselines.tsv`.
- **Jamais de fix sans validation humaine (ADR-031)** : aucune action de cette phase n'a besoin de
  cette clause au sens strict (pas de correctif réactif à un incident), mais la mise en conformité du
  corpus (D-11) EST une décision déjà validée par Willy (délégation explicite du cadrage) — le plan
  peut donc exécuter directement, sans checkpoint humain supplémentaire, sur les 9 corrections
  identifiées et vérifiées ici.
- **Agents natifs machine-enforced (ADR-044)** : cette phase EST le mécanisme ADR-044 lui-même qui
  évolue — aucune action supplémentaire requise au-delà de ce que FABR-01 à FABR-05 couvrent déjà.
- **Commits en français**, cohérents avec l'historique du dépôt (patron déjà illustré par les
  citations de commits dans ce document).
- **Traçabilité des arbitrages** : le cadrage de cette phase cite déjà « Willy, AskUserQuestion
  session principale, 2026-09-23 » en en-tête de `42-CONTEXT.md` — toute décision de cette recherche
  qui découle directement d'un D-xx du cadrage n'a pas besoin d'une citation supplémentaire ; toute
  décision NOUVELLE prise au plan (ex. nom exact du flag CLI) reste Claude's Discretion, sans
  arbitrage humain à citer.
- **Modules `plugin/` et `.planning/` commités séparément** : les commits de correctif de corpus
  (D-12, par module) et les commits du gate (conductor) restent distincts des commits de planning
  éventuels de cette recherche — cohérent avec le `commit_docs: true` de `.planning/config.json`.

## Sources

### Primary (HIGH confidence)
- `code.claude.com/docs/en/sub-agents` (WebFetch, 2026-09-23) — liste complète des 18 champs de
  frontmatter, sémantique exacte d'`omitClaudeMd` et `experimental`, types natifs, priorité de
  résolution des noms, allowlists `Agent(...)`.
- `code.claude.com/docs/en/tools-reference` (WebFetch, 2026-09-23) — liste exhaustive et faisant
  autorité des 46 identifiants d'outils, incluant `ListAgents`, `SendFeedback`, `SubagentHandback`
  (confirmés absents de `TOOL_NAMES` actuel) et confirmant l'absence de `SlashCommand`, `BashOutput`,
  `KillShell` sous ces noms exacts.
- `/websites/code_claude` via context7 (2026-09-23) — `TaskOutput` documenté comme remplaçant de
  `BashOutput` (« formerly BashOutput »), `TaskStop` documenté comme alias canonique de
  `KillShell`/`KillBash`.
- Lecture directe du code source : `plugin/conductor/scripts/check-agents.sh` (708 lignes),
  `plugin/conductor/scripts/guard-agent-write.sh`, `plugin/conductor/scripts/tests/test-check-agents.sh`
  (1504 lignes, T76 lignes 1393-1460), `plugin/conductor/references/team-kernel.md`,
  `plugin/_internal/vibeflow-update.sh` (`copy_module_scripts()` lignes 1965-2028),
  `plugin/conductor/scripts/check-instruction-budget.sh`, `scripts/check-baseline-arbitrage.sh`,
  `scripts/check-gate-touche.sh`, `.github/workflows/ci.yml` (lignes 230-330, 1280-1330),
  `plugin/conductor/hooks/hooks.json`, `.planning/instruction-budget-baselines.tsv`,
  `.planning/config.json`, les 9 fichiers agents du corpus réel (mesures directes sur disque).
- `git show origin/fix/blueprints-conformite-gate:plugin/conductor/scripts/check-blueprints.sh`
  (PR #85) — lu intégralement, confirme le shell-out vers `check-agents.sh --file`.

### Secondary (MEDIUM confidence)
- Aucune — toutes les sources critiques ont été vérifiées directement (fichiers du dépôt ou pages
  doc officielles).

### Tertiary (LOW confidence)
- WebFetch de `code.claude.com/docs/en/sub-agents` mentionnant un type natif `claude` (catch-all) —
  UNE SEULE source, non recoupée par `tools-reference` ni par une seconde lecture — traité comme
  `[ASSUMED]` non retenu (Assumptions Log A3).
- WebSearch sur `SlashCommand`/`BashOutput`/`KillShell` — résultats non officiels, contredits par le
  WebFetch direct des deux pages faisant autorité ; retenu uniquement comme signal que ces noms
  circulent dans la communauté, pas comme preuve de leur existence en tant qu'identifiants distincts.

## Metadata

**Confidence breakdown :**
- Manifeste + fraîcheur (FABR-01/02) : HIGH — mécanique entièrement dérivée de patrons déjà en place
  dans ce même dépôt (`vf_manifest_valid()`, `--resolve-agents=lenient|strict`, contrat F13),
  aucune dépendance nouvelle.
- Invariants I1-I7 (FABR-03) : HIGH — les 9 violations et leurs corrections exactes ont été mesurées
  fichier par fichier sur le disque réel, pas déduites de la spec seule.
- Découverte récursive (FABR-04) : MEDIUM — aucun cas réel n'existe dans le corpus actuel pour
  valider l'exclusion sur pièce ; la preuve reposera entièrement sur une fixture synthétique (posé
  comme limite honnête, pas comme lacune cachée).
- Mise en conformité du corpus (FABR-05) : HIGH — vérifiée contre le disque réel, y compris la
  découverte que T76 est déjà correct (le point le plus surprenant de cette recherche).
- Sémantique `omitClaudeMd` : HIGH pour ce qu'elle omet (citation verbatim de la doc officielle) ;
  MEDIUM sur son interaction avec `rules/*.md` (non mentionnée explicitement dans la doc — inférence
  raisonnable, non testée en conditions réelles, cf. Assumptions A2).

**Research date :** 2026-09-23
**Valid until :** 30 jours (2026-10-23) — cohérent avec le `valide_jours: 30` que cette même phase
introduit pour le manifeste qu'elle produit ; au-delà, revérifier `tools-reference`/`sub-agents`
avant de réutiliser ce document pour re-planifier.
