# Phase 20: Fluidité du flux de dev sans perte de qualité - Pattern Map

**Mapped:** 2026-07-29
**Files analyzed:** 20 (6 modules bumpés, ~19 fichiers modifiés + 1 nouveau `.md` + 1 nouveau script + tests)
**Analogs found:** 20 / 20 — cette phase est **100% extension additive** de mécanismes déjà écrits dans
ce repo (confirmé par 20-RESEARCH.md, aucun nouveau pattern à importer de l'extérieur). Tous les
fichiers cibles sont soit modifiés directement (analog = eux-mêmes avant modification, patron déjà
posé ailleurs dans le même fichier ou un fichier jumeau), soit un nouveau fichier calqué sur un
gabarit existant identifié nommément par la recherche.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/dev-orchestrator/agents/vf-reviewer.md` | config (agent frontmatter) | request-response | `plugin/dev-orchestrator/agents/vf-coder.md:8` (`vf-mcp-consumer: true` déjà posé) | role-match |
| `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` | utility (install-time transform) | transform | lui-même, mode wildcard existant (lignes 149-166) | exact (extension du même fichier) |
| `docs/ADR.md` (révision ADR-051, lignes 356-437) | config/doc | transform | lui-même — patron de révision ciblée déjà pratiqué (ADR-059 récent) | exact |
| `plugin/design-orchestrator/agents/vf-design-judge.md` | config (agent frontmatter) | request-response | 3 juges jumeaux ci-dessous, patron identique | exact |
| `plugin/business-pilot-bundle/agents/quality-gate-client.md` | config (agent frontmatter) | request-response | `vf-design-judge.md` (même changement `disallowedTools`) | exact |
| `plugin/content-bundle/agents/content-clarity-judge.md` | config (agent frontmatter) | request-response | idem | exact |
| `plugin/growth-bundle/agents/growth-quality-judge.md` | config (agent frontmatter) | request-response | idem | exact |
| `plugin/conductor/references/team-kernel.md` | doc (doctrine) | transform | lui-même, ligne 23 (motif « Agent(...) sous-agent » déjà présent, patron à répliquer pour AskUserQuestion) | exact |
| `plugin/conductor/README.md` | doc (vitrine) | transform | `team-kernel.md:23` (même formule à corriger en miroir) | exact |
| `plugin/dev-orchestrator/agents/vf-dev-manager.md` | controller (orchestrateur) | event-driven | `plugin/dev-orchestrator/references/mission-cross-team.md:36-45` (nœud `revue-N` déjà posé pour design croisé) | exact |
| `plugin/dev-orchestrator/agents/vf-coder.md` | controller (worker) | event-driven | lui-même (retrait de section, aucun analog externe requis) | exact |
| `plugin/dev-orchestrator/references/mission-cross-team.md` | doc (référence) | transform | inchangé — sert de source, pas de cible | n/a (source) |
| `plugin/dev-orchestrator/references/mission-contracts.md` | doc (contrat) | transform | inchangé dans son format (D-17) | n/a (pas de modif structurelle) |
| `plugin/conductor/scripts/dag.sh` (`--scope`, `review_regime`) | utility (state machine JSON) | CRUD | lui-même — patron `--deps` existant (parsing arg, lignes 26-39, 99) | exact |
| `.planning/MISSION-INVARIANTS.md` | config (doc de planning) | transform | aucun template exact dans le repo — gabarit calqué sur `check-doc-drift.sh` en esprit (advisory, falsifiable) | role-match |
| `plugin/conductor/scripts/check-mission-invariants.sh` (nouveau) | utility (gate advisory) | batch | `plugin/dev-orchestrator/scripts/check-doc-drift.sh` | exact (gabarit nommé par la recherche) |
| `plugin/conductor/hooks/hooks.json` | config (câblage hooks) | event-driven | lui-même — patron `{{VF_SCRIPTS}}` déjà résolu par `merge-hooks.sh:167` | exact |
| `plugin/conductor/scripts/check-agents.sh` (scope, charset, `--hook`) | utility (gate CI) | batch | lui-même — 3 correctifs ciblés sur du code existant (lignes 78-79, 355, 568-571) | exact |
| `plugin/conductor/scripts/check-debug-research.sh` (scope, `--third-party-prefix`) | utility (gate CI) | batch | `plugin/conductor/scripts/check-agents.sh` (mécanisme `--third-party-prefix` à porter tel quel, lignes 84,96-100,580-586) | exact |
| `plugin/conductor/scripts/tests/test-check-agents.sh` | test | batch | lui-même — `run_check()` ligne 94, cas à ajouter sur le même patron `ok()`/`ko()` | exact |
| `plugin/conductor/scripts/tests/test-check-debug-research.sh` | test | batch | `test-check-agents.sh` (même patron `ok()`/`ko()`, `run_check()` ligne 36) | exact |
| `plugin/conductor/scripts/tests/test-dag.sh` | test | batch | lui-même — cas `--deps` existants à répliquer pour `--scope`/`reopen` | exact |
| `plugin/conductor/scripts/tests/test-check-mission-invariants.sh` (nouveau) | test | batch | `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` | exact (gabarit nommé) |
| `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` | test | batch | lui-même — 10 cas existants, patron à répliquer pour le mode nommé D-05 | exact |

## Pattern Assignments

### `plugin/dev-orchestrator/agents/vf-reviewer.md` (config, request-response)

**Analog:** `plugin/dev-orchestrator/agents/vf-coder.md:8` (marqueur `vf-mcp-consumer: true`)

**Contrainte non négociable (D-05)** : le fichier SOURCE `vf-reviewer.md` **ne change pas** son
`tools:` littéral (0 occurrence `mcp__` en dur dans tout `plugin/*/agents/*.md`, vérifié). Seul un
marqueur de frontmatter dédié (nom à choisir — recommandé : liste séparée dans le script plutôt que
réutiliser `vf-mcp-consumer:` avec une valeur non-booléenne, cf. Open Question D-05 de RESEARCH.md)
déclenche le nouveau mode d'injection.

**État actuel** (`vf-reviewer.md:4`) :
```yaml
tools: Read, Bash, Glob, Grep, Agent(gsd-code-reviewer)
```

**Frontmatter cible au RUNTIME uniquement** (jamais commité, injecté par le script) :
```yaml
tools: Read, Bash, Glob, Grep, Agent(gsd-code-reviewer), mcp__XcodeBuildMCP__test_sim, mcp__XcodeBuildMCP__build_sim, mcp__XcodeBuildMCP__clean
```

**Protocole à documenter dans le corps de l'agent (Pitfall 3/4)** : imposer `clean` avant tout
`build_sim`/`test_sim` de vérification, et exiger que chaque appel porte
`projectPath`/`scheme`/`simulatorId` explicitement (pas de défaut de session partagé).

---

### `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (utility, transform)

**Analog:** lui-même — mode wildcard existant (lignes 149-166), à étendre sans le modifier.

**Nouveau mode named-tool (squelette, D-05)** :
```python
NAMED_FLAG_RE = re.compile(r"^vf-mcp-consumer:\s*xcodebuildmcp-review-only\s*$", re.M)
NAMED_TOKENS = ["mcp__XcodeBuildMCP__test_sim", "mcp__XcodeBuildMCP__build_sim",
                "mcp__XcodeBuildMCP__clean"]

def has_named_flag(text):
    span, lines = frontmatter_block(text)
    if span is None:
        return False
    fm = "\n".join(lines[span[0]:span[1]])
    return bool(NAMED_FLAG_RE.search(fm))
# Un fichier avec le marqueur nommé reçoit NAMED_TOKENS au lieu de want_tokens (wildcard) —
# SEULEMENT si un serveur "XcodeBuildMCP" est détecté dans .mcp.json. Absent → no-op silencieux
# (best-effort, cohérent avec le reste du mécanisme ADR-051).
```

**Error handling / best-effort pattern** : identique au mode existant — absence de `.mcp.json` ou de
serveur nommé XcodeBuildMCP → aucune injection, silence, jamais d'erreur bruyante.

---

### 4 juges — `disallowedTools: Write, Edit` (config, request-response)

**Fichiers** : `plugin/design-orchestrator/agents/vf-design-judge.md`,
`plugin/business-pilot-bundle/agents/quality-gate-client.md`,
`plugin/content-bundle/agents/content-clarity-judge.md`,
`plugin/growth-bundle/agents/growth-quality-judge.md`.

**Analog:** patron identique répliqué sur les 4 — aucun n'a besoin d'analog externe, ce sont des
jumeaux entre eux. `check-agents.sh:154-156` connaît déjà `disallowedTools` dans `KNOWN` — aucun
changement de gate requis.

**Avant → Après** (`vf-design-judge.md:4-6`) :
```yaml
# AVANT
tools: Read, Bash, Glob, Grep
# APRÈS
tools: Read, Bash, Glob, Grep
disallowedTools: Write, Edit
```

**Nuance à documenter (D-07, seul `vf-design-judge` porte `Bash`)** : ne plus écrire « read-only »
sans qualification pour cet agent — remplacer par « sans Write/Edit directs ; `Bash` reste
accessible, l'absence d'écriture est un contrat de prompt sur ce canal, pas une barrière runtime ».
Les 3 juges de bundle (pas de `Bash`) sont read-only complets après ce changement.

---

### `plugin/conductor/references/team-kernel.md` + `plugin/conductor/README.md` (doc, transform)

**Analog:** `team-kernel.md:23` lui-même — la ligne contient déjà le patron de parenthétique
« restriction analogue » à répliquer pour le nouveau constat D-09.

**Correction ciblée (D-08)** — `team-kernel.md:23` et `README.md:44`, formule identique :
```diff
- juges sans Write/Edit
+ juges sans Write/Edit (`disallowedTools`)
```
**Attention** : `team-kernel.md:36` ne porte PAS la formule « Write/Edit » (contrairement au rapport
de mission du matin) — vérifier sur pièce avant d'éditer, ne pas éditer cette ligne sans relecture.

**Ajout du sens FERMETURE (D-09)**, à côté de la ligne 23, même famille de constat que la restriction
`Agent(...)` déjà documentée en parenthèses :
```markdown
# Patron à copier tel quel, source: plugin/dev-orchestrator/agents/vf-coder.md (§Cadrage) :
« Tu n'as pas `AskUserQuestion` : une question de cadrage que les assumptions documentées ne
couvrent pas → statut `human_needed` remonté au manager, JAMAIS auto-répondue en silence. »
```
Ce même filet doit être ajouté au corps de `vf-dev-manager.md` (près de ses usages actuels
d'`AskUserQuestion`, lignes 21 et 141).

---

### `plugin/dev-orchestrator/agents/vf-dev-manager.md` (controller, event-driven)

**Analog:** `plugin/dev-orchestrator/references/mission-cross-team.md:36-45` — le nœud `revue-N` est
déjà écrit pour l'étage design croisé, à généraliser (pas à inventer).

**Core pattern — pose systématique du nœud `revue-N`** (source `mission-cross-team.md:44`) :
```bash
"$S"/dag.sh add --file="$DAG" --id=exec-N   --step="exécution étape N" --deps=plan-N --scope="src/module-x/**"
"$S"/dag.sh add --file="$DAG" --id=revue-N  --step="revue code étape N" --deps=exec-N
# Dispatch vf-reviewer DIRECTEMENT (jamais via vf-coder).
# Sur gaps_found : dispatch vf-coder en mandat FIX CIBLÉ, puis dag.sh reopen --id=revue-N →
# re-dispatch vf-reviewer, jusqu'à 3 tours (budget), au-delà remonte au manager.
```

**Réécriture de « pas de double revue »** (`vf-dev-manager.md:107-110`) :
```markdown
# AVANT
**Pas de double revue** : si le rapport typé de `vf-coder` est `passed` avec verdict revue PASS,
ne re-dispatche pas de revue de code sur la même étape — seuls Test/Audit s'ajoutent.

# APRÈS (esprit à préserver, forme exacte laissée au planner)
**La revue est un nœud DAG `revue-N` systématique** (deps=`exec-N`), dispatchée directement
(jamais via `vf-coder`) : sur `gaps_found`, `dag.sh reopen --id=revue-N` puis dispatch `vf-coder`
en mandat FIX CIBLÉ uniquement (pas un cycle complet), jusqu'au PASS ou budget (3 tours max —
au-delà, escalade).
```

**Formulation exacte à préserver mot pour mot (garde-fou non négociable de la phase)** :
« Aucun allègement ne s'applique jamais à un diff de comblement […] Une re-revue reste pleine,
quelle que soit la nature du lot d'origine. »

**Critères objectifs de gradation (D-12)**, jamais au feeling — (a) adaptateur d'infra non couvert par
les tests, (b) fichier partagé avec mission parallèle en vol (nécessite `--scope`), (c) code non
couvert par la mutation, (d) geste utilisateur/géométrie de vue → revue **pleine** non négociable.
Jointure obligatoire déclenchée par la **topologie du DAG** (paire de nœuds `exec` incomparables
partage un descendant `join`), jamais par intersection de fichiers.

---

### `plugin/dev-orchestrator/agents/vf-coder.md` (controller, event-driven)

**Analog:** lui-même — retrait de section, patron de contraction déjà illustré par RESEARCH Ex.3.

**Avant → Après** (§« Le cycle (délégation) », étape 4) :
```markdown
# AVANT (4 étapes)
4. **Revue** : dispatche l'agent `vf-reviewer` (outil Agent) sur le diff de l'étape. S'il remonte
   des correctifs bloquants, boucle : fix ciblé puis re-revue, jusqu'au PASS ou budget (3 tours max).

# APRÈS (3 étapes)
3. **Exécution** : ... (dernier appel du cycle — la revue n'est plus dispatchée par vf-coder, elle
   vit désormais comme nœud DAG `revue-N` piloté directement par vf-dev-manager)
```
**Piège à éviter** : l'allowlist `Agent(vf-reviewer, ...)` du `tools:` frontmatter reste INCHANGÉE
(sert encore, ex. remontée d'un besoin de recherche) — ne pas la retirer en supprimant le texte du
cycle.

---

### `plugin/conductor/scripts/dag.sh` (utility, CRUD)

**Analog:** lui-même — patron `--deps` déjà en place (parsing arg boucle lignes 26-39, split `,`
ligne 99).

**`--scope` additif (D-13)** :
```bash
# Parsing d'arguments (~ligne 26-38) :
    --scope=*)  SCOPE="${arg#*=}" ;;
# sys.argv du bloc python3 (ligne 44) :
#   action, file, nid, step, stage, deps_raw, status, scope_raw = sys.argv[1:9]
# Bloc "add" (ligne 88-108), après le calcul de deps :
    scope = [s.strip() for s in scope_raw.split(",") if s.strip()]
    node = {"id": final, "step": step, "stage": stage, "deps": deps, "scope": scope, "status": "blocked"}
# Rétro-compat obligatoire : node.get("scope", []) partout où consommé — jamais un KeyError sur
# les nœuds existants dans les DAG déjà écrits.
```

**`review_regime: "full"` forcé par `reopen` (D-14)**, bloc `reopen` (lignes 127-149) :
```bash
    for d in affected:
        idx[d]["status"] = "blocked"
        if idx[d]["id"].startswith(("revue-", "join")):
            idx[d]["review_regime"] = "full"
    if idx[nid]["id"].startswith(("revue-", "join")):
        idx[nid]["review_regime"] = "full"
```
Enforcement machine, pas doctrine seule — cohérent avec l'axiome du repo « enforcement > prose ».

---

### `.planning/MISSION-INVARIANTS.md` (nouveau, config/doc, transform)

**Analog:** aucun template exact dans le repo (fichier absent aujourd'hui) — squelette fourni
verbatim par RESEARCH Ex.7, calqué en esprit sur `check-doc-drift.sh` (advisory, falsifiable, jamais
de copie figée).

```markdown
# Mission Invariants

## Zones de risque (globs, falsifiable machine)
> Un glob qui ne matche plus aucun fichier du repo est une "zone morte" — détecté par
> check-mission-invariants.sh (patron check-doc-drift.sh).
- `plugin/*/scripts/*-adapter.sh`     # adaptateur d'infra non injectable
- ...

## Table des fichiers gelés — lue À LA DEMANDE, jamais recopiée
Cette table N'EST PAS statique. Interroger le --scope des nœuds `blocked`/en cours des DAG actifs :
  dag.sh status --file=.planning/missions/dag-<mission-active>.json

## [NON GATÉ] Contrainte d'outillage du moment — à revérifier manuellement à chaque mission
> Fait documenté, pas de mécanisme falsifiable pour cette section (D-16).
- XCODEBUILDMCP_DISABLE_SESSION_DEFAULTS=true requis.
- Chaque appel build_sim/test_sim DOIT porter projectPath/scheme/simulatorId explicitement.
```

**Contrainte non négociable (D-15)** : ne JAMAIS recopier statiquement la table des fichiers gelés
(« s'il ment, il est pire que rien », précédent d'un `CLAUDE.md` mensonger cité explicitement).

---

### `plugin/conductor/scripts/check-mission-invariants.sh` (nouveau, utility, batch)

**Analog:** `plugin/dev-orchestrator/scripts/check-doc-drift.sh` — patron canonique advisory du repo.

**Contrat de sortie F13 à répliquer** :
```bash
# Usage: check-mission-invariants.sh [--path <dir>] [--hook] [--quiet]
# Pour chaque glob de §1 "Zones de risque" : git ls-files -- '<glob>' | wc -l   # 0 = zone morte
# Exit 0 = zone morte détectée (signal [mission-invariants-drift])
# Exit 3 = tous les globs matchent encore ≥1 fichier (rien à signaler)
# Exit 64 = argument invalide / fichier MISSION-INVARIANTS.md absent ou illisible
```
**Principe FAIT vs JUGEMENT (ADR-055 §3)** : le script **constate** qu'un glob ne matche plus rien,
il ne **décide** jamais de le retirer.

---

### `plugin/conductor/hooks/hooks.json` (config, event-driven)

**Analog:** lui-même — le placeholder `{{VF_SCRIPTS}}` est déjà résolu globalement par
`plugin/_internal/merge-hooks.sh:167` (`.replace()` Python), aucun nouveau code de substitution requis.

```json
// AVANT
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-agents.sh --hook || true" },
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-debug-research.sh --hook || true" },

// APRÈS (D-18, D-19)
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-agents.sh --hook --agents-dir={{VF_SCRIPTS}}/../agents --skills-dir={{VF_SCRIPTS}}/../skills || true" },
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-debug-research.sh --hook --agents-dir={{VF_SCRIPTS}}/../agents --skills-dir={{VF_SCRIPTS}}/../skills || true" },
```

---

### `plugin/conductor/scripts/check-agents.sh` (utility, batch — 3 correctifs ciblés)

**Analog:** lui-même — chaque correctif touche une zone de code déjà écrite et documentée par ligne.

**1. Charset MCP (D-22, ligne 355)** :
```python
# AVANT
if not re.fullmatch(r"[A-Za-z0-9_-]+", tok):
    errors.append(f"{base} : {field} — token hors charset attendu '{tok}'")
    return None, None
# APRÈS — accepter UNIQUEMENT un `*` FINAL après mcp__<serveur>__, jamais en milieu de chaîne
if not (re.fullmatch(r"[A-Za-z0-9_-]+", tok) or re.fullmatch(r"mcp__[A-Za-z0-9_-]+__\*", tok)):
    errors.append(f"{base} : {field} — token hors charset attendu '{tok}'")
    return None, None
```

**2. Warnings conditionnels en `--hook` (D-21, lignes ~568-596)** :
```python
# AVANT
if hook:
    if n_err:
        print(f"[check-agents] ✗ {n_err} agent(s) non conforme(s) :")
        for e in errors: print(f"  - {e}")
        print("  Corriger le frontmatter puis relancer : bash .claude/scripts/check-agents.sh")
    sys.exit(0)
# APRÈS — patron « silence nominal, signal si présent », calqué sur update-banner.sh
if hook:
    if n_err:
        print(f"[check-agents] ✗ {n_err} agent(s) non conforme(s) :")
        for e in errors: print(f"  - {e}")
        print("  Corriger le frontmatter puis relancer : bash .claude/scripts/check-agents.sh")
    elif n_warn:
        print(f"[check-agents] ⚠ {n_warn} avertissement(s) (voir bash .claude/scripts/check-agents.sh)")
    sys.exit(0)
```

**3. Scope (D-18, lignes 78-79)** — `AGENTS_DIR`/`SKILLS_DIR` sont déjà des flags `--agents-dir`/
`--skills-dir` consommés par le script ; le fix vit dans `hooks.json` (voir ci-dessus), pas ici — ne
pas modifier les défauts eux-mêmes (rétro-compatibilité CLI directe hors hook).

**Pièges obligatoires liés (D-24, D-21↔D-18 même commit)** : voir section Tests ci-dessous.

---

### `plugin/conductor/scripts/check-debug-research.sh` (utility, batch)

**Analog:** `plugin/conductor/scripts/check-agents.sh` — porter `--third-party-prefix` tel quel
(défaut `gsd-`), pas de second mécanisme.

**Mécanisme à répliquer** (source `check-agents.sh:84,96-100,580-586`) : variable
`THIRD_PARTY_PREFIXES`, parsing `--third-party-prefix=*` / `--no-third-party-prefix`, filtrage par
`dname.startswith(pfx)` avant `check_file()`.

**Scope (D-18/D-19)** : mêmes 2 flags `--agents-dir`/`--skills-dir` déjà disponibles (lignes 48-49,
confirmé) — le fix vit dans `hooks.json`, symétrique au traitement de `check-agents.sh`.

---

### Suites de tests (D-24, obligatoire pour tout plan touchant D-18/D-19/D-20/D-21/D-22)

**Analog:** `plugin/conductor/scripts/tests/test-check-agents.sh` (`run_check()` ligne 94) et
`test-check-debug-research.sh` (`run_check()` ligne 36) — patron `ok()`/`ko()` maison, `mktemp -d`.

**Cas obligatoire, jamais couvert aujourd'hui** : `run_check()` passe TOUJOURS `--agents-dir`/
`--skills-dir` en dur — aucun cas n'exerce le chemin par défaut. Ajouter un cas dédié : `cd` dans un
répertoire de test sans `.claude/agents`, invoquer le script **sans** ces flags, vérifier le
comportement par défaut. C'est précisément l'angle mort qui a laissé le bug de scope survivre à toute
la Phase 16.

**`test-dag.sh`** : répliquer le patron des cas `--deps` existants pour `--scope` (rétro-compat sur
nœuds sans champ) et pour `reopen` (assertion `review_regime == "full"` sur nœuds `revue-*`/`join`).

**`test-check-mission-invariants.sh`** (nouveau) : gabarit exact `test-check-doc-drift.sh` — cas glob
mort détecté / glob vivant silencieux.

**`test-inject-mcp-tools.sh`** : 10 cas existants — ajouter le mode nommé D-05 (marqueur présent +
serveur XcodeBuildMCP présent → 3 tokens ; marqueur absent → wildcard inchangé ; serveur absent →
no-op silencieux).

## Shared Patterns

### Best-effort sans dégradation (D-05, D-15)
**Source:** mécanisme ADR-051 existant dans `inject-mcp-tools.sh`
**Apply to:** tout mécanisme dont la source de vérité externe (`.mcp.json`, DAG de mission) peut être
absente — absence = silence, jamais une erreur bloquante.

### Enforcement machine > prose (D-14, D-06)
**Source:** axiome documenté du repo, illustré par `disallowedTools` (barrière runtime réelle) et
`review_regime` écrit par `dag.sh reopen`
**Apply to:** tout invariant non négociable de cette phase (garde-fou anti-allègement de comblement) —
préférer un champ/flag vérifiable machine à une simple consigne de prompt.

### FAIT vs JUGEMENT — ADR-055 §3
**Source:** `plugin/dev-orchestrator/scripts/check-doc-drift.sh`
**Apply to:** `check-mission-invariants.sh` (nouveau) et tout script advisory — un script constate
(glob mort, warning count), il ne décide/juge jamais.

### Contrat de sortie « silence nominal, signal explicite sinon »
**Source:** `plugin/conductor/scripts/update-banner.sh`
**Apply to:** `check-agents.sh --hook` (D-21), `check-mission-invariants.sh` — silencieux à 0
finding, imprime seulement s'il y a quelque chose à dire.

### Extension additive plutôt que réécriture/duplication
**Source:** doctrine explicite de RESEARCH.md §Don't Hand-Roll
**Apply to:** TOUS les fichiers de cette phase sans exception — chaque changement a un précédent exact
à étendre (`inject-mcp-tools.sh` mode existant, `mission-cross-team.md` nœud `revue-N` déjà posé,
`--third-party-prefix` déjà livré Phase 16, `check-doc-drift.sh` gabarit advisory).

## No Analog Found

Aucun fichier de cette phase n'est sans analog — tous les 5 changements sont des extensions
additives de mécanismes déjà présents dans le repo (confirmé par RESEARCH.md §Summary : « chaque
changement a un précédent exact à répliquer, jamais à inventer »). Le seul élément structurellement
neuf est le contenu narratif de `.planning/MISSION-INVARIANTS.md` (pas de template exact), mais son
gabarit (advisory, falsifiable, jamais de copie figée) est directement dérivé de `check-doc-drift.sh`.

## Metadata

**Analog search scope :** `plugin/conductor/`, `plugin/dev-orchestrator/`, `plugin/design-orchestrator/`,
`plugin/business-pilot-bundle/`, `plugin/content-bundle/`, `plugin/growth-bundle/`, `docs/ADR.md`,
`.planning/`.
**Files scanned :** 20 fichiers cibles + ~10 fichiers analog/source déjà lus intégralement par
20-RESEARCH.md (2026-07-29, vérification sur pièce, zéro dérive constatée).
**Pattern extraction date :** 2026-07-29
**Note de méthode :** cette carte de patterns n'a pas eu besoin de relire les fichiers sources — la
recherche en amont (20-RESEARCH.md) a déjà extrait chaque excerpt avec numéros de ligne exacts,
vérifiés sur pièce le 2026-07-29. Ce document réorganise ces excerpts par fichier cible pour
consommation directe par le planner, sans duplication de lecture.

---

*Phase: 20-Fluidité du flux de dev sans perte de qualité*
*Patterns mapped: 2026-07-29*
