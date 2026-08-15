# Phase 24: Activation et mesure du moteur GSD — Pattern Map

**Mapped:** 2026-08-04
**Files analyzed:** 15 (12 modifiés, forme de 3 créés à proposer)
**Analogs found:** 15 / 15

**Nature du dépôt :** bash + markdown, pas de code applicatif. Les patterns qui comptent sont des
**conventions de script de gate** (structure `ok`/`ko`, codes de sortie, messages stderr), la
**forme d'un cas de test** dans `test-dev-orchestrator.sh`, la **forme d'une entrée d'ADR**, et la
**forme d'un frontmatter d'agent**. Aucun analog n'est du code TS/JS applicatif.

## File Classification

| Fichier à créer/modifier | Rôle | Flux de données | Analogue le plus proche | Qualité du match |
|---|---|---|---|---|
| `.planning/config.json` (clés `agent_skills.gsd-planner`, `workflow.windows_enforce`, `hooks.workflow_guard`, `intel.enabled`) | config | CRUD (édition ponctuelle) | lui-même (fichier déjà existant, forme JSON stable) | exact |
| `plugin/conductor/scripts/check-agents.sh:514-516` | gate/utility | request-response (validation) | lui-même — durcir un bloc de validation voisin (`model`, `memory`) déjà « exige » dans le même fichier | exact |
| `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh:111` | gate/utility | request-response | `plugin/conductor/scripts/check-state-integrity.sh` (même famille de gate constat-only, chemin en dur à généraliser) | exact |
| `plugin/conductor/scripts/check-state-integrity.sh:53` | gate/utility | request-response | `check-dev-bootstrap.sh` (repli PLANNING_DIR configurable par env) | exact |
| `plugin/planning-core/scripts/planning-context.sh` (localisé : `plugin/planning-core/scripts/planning-context.sh`) | utility (injection SessionStart) | event-driven (hook) | `check-dev-bootstrap.sh` pour le patron `PLANNING_DIR="${VF_X_PLANNING_DIR:-$ROOT/.planning}"` | role-match |
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (extension gate T14) | test | request-response (assertions) | lui-même — bloc T14 existant (`:1289-1321`) à étendre, + patron `mutant()` de `test-check-gsd-config.sh:1210-1225` pour la discriminance par mutation | exact |
| `plugin/conductor/AGENT.md:114` (Iron Law 2) | doctrine/config | — | lui-même — bloc `## Iron Laws` (`:111-117`) | exact |
| `plugin/*/agents/*.md` (~25 fichiers, ajout `effort:`) | config (frontmatter agent) | CRUD | `plugin/reference/content/methodology/templates/agents/business-agent-template.md` (`effort: medium`), `clarity-feature-template.md` (`high`), `orchestrator-template.md` (`high`) | exact |
| `plugin/dev-orchestrator/references/intent-routing.md:104,147` | route/config | request-response (table de routage) | lui-même — entrées voisines déjà marquées conditionnelles (à repérer au plan) | exact |
| `plugin/dev-orchestrator/references/docs-flow.md:43-44` | route/config | request-response | `intent-routing.md` (même famille de table) | role-match |
| `docs/ADR.md` (nouvelles entrées à partir d'ADR-066) | doctrine (document) | — | `docs/ADR.md` — ADR-063 (`:1288-1331`) et ADR-064 (`:1459+`), entrées les plus récentes | exact |
| `plugin/dev-orchestrator/references/gsd-capabilities-index.md` | config (index généré) | batch (généré depuis le disque) | lui-même (Phase 23, D-07) — patron `build-gsd-index.sh` → `gsd-skills-index.md` | exact |
| `.github/workflows/ci.yml` (extension aux chemins workstream) | config (CI) | batch | lui-même — job `tests` (`:14-40`), principe « 0 découverte = échec, jamais vert par absence de cible » | exact |
| **Créé : gate d'activation doc ↔ capability** | gate/utility (à créer) | request-response | `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` (forme complète : docstring contractuelle, exits numérotés, `say()`, gate d'arguments avant logique) | role-match |
| **Créé : gate sur le pointeur de session workstream** | gate/utility (à créer) | request-response | `plugin/conductor/scripts/check-state-integrity.sh` (forme : invariant vérifié contre un état de référence, codes 0/1/2/64, jamais de repli faible) | role-match |
| **Créé : texte de remontée amont (gabarit issue #2598)** | doc | — | précédent narratif déjà cité en zone 5 (mission `2026-07-31-mesure-m2-dispatch-parallele.md`, voie 2) — à lire pour la forme, hors scope lecture de ce mapping | no-analog-direct |

## Pattern Assignments

### `plugin/conductor/scripts/check-agents.sh:514-516` (gate, request-response)

**Analogue :** lui-même — les blocs `model` (`:502-506`) et `memory` (`:508-512`) sont déjà en
mode « exige », juste au-dessus du bloc `effort` en mode « valide si présent ».

**Pattern actuel à durcir** (lignes 514-516, extrait exact) :
```python
    effort = fm.get("effort")
    if effort and effort not in EFFORT:
        errors.append(f"{base} : effort invalide ({effort}) — attendu low|medium|high|xhigh|max")
```

**Pattern cible — copier la forme du bloc `model` juste au-dessus** (lignes 502-506) :
```python
    model = fm.get("model")
    if not model:
        errors.append(f"{base} : model absent — souverainete modele requise (sonnet|opus|haiku|fable|inherit)")
    elif model not in MODELS and not re.fullmatch(r"claude-[a-z0-9.-]+", str(model)):
        errors.append(f"{base} : model invalide ({model}) — attendu sonnet|opus|haiku|fable|inherit|claude-<id>")
```
→ Transposer littéralement : `if not effort: errors.append(...)` puis `elif effort not in EFFORT: errors.append(...)`.
La liste `EFFORT` existe déjà (`:163`) : `EFFORT = {"low", "medium", "high", "xhigh", "max"}`.

---

### `plugin/*/agents/*.md` — ajout de `effort:` (config, frontmatter)

**Analogue :** `plugin/reference/content/methodology/templates/agents/business-agent-template.md`

**Frontmatter avec `effort:` déjà posé** (lignes 1-9) :
```yaml
---
name: business-agent-[DOMAINE]
description: Agent metier specialise sur un domaine business non-tech...
model: sonnet
effort: medium
skills:
  - [SKILL_DOMAINE_1]
  - [SKILL_DOMAINE_2]
memory: project
---
```

**Cible réelle sans `effort:` à corriger** — ex. `plugin/dev-orchestrator/agents/vf-coder.md:1-9`,
frontmatter actuel (aucun champ `effort`) :
```yaml
---
name: vf-coder
description: Pilote le cycle de dev d'une étape (cadrage → plan → exécution)...
tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent(...)
model: sonnet
memory: project
vf-internal: true
vf-mcp-consumer: true
---
```
→ Insérer `effort: <barème>` entre `model:` et `memory:` (position observée dans le template),
valeur choisie par rôle (pilotage/jugement → `high`/`max` ; exécution mécanique → `low`/`medium`),
jamais uniformément (verdict zone 6).

Barème déjà écrit ailleurs, à propager tel quel : `clarity-feature-template.md` → `effort: high`,
`orchestrator-template.md` → `effort: high`.

---

### `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh:111` (gate, request-response)

**Analogue pour la forme workstream-aware :** le fichier lui-même applique déjà le patron « chemin
racine surchargeable par variable d'environnement, avec défaut sur `.planning` » pour
`PLANNING_DIR` :

```bash
PLANNING_DIR="${VF_BOOTSTRAP_PLANNING_DIR:-$ROOT/.planning}"
```

Le chemin en dur à corriger est `roadmap_missing()` :
```bash
roadmap_missing() {
  local f="$PLANNING_DIR/ROADMAP.md"
  [ -f "$f" ] || return 0
  ...
}
```
→ Le rendre workstream-aware suit le même patron de surcharge par env déjà appliqué à
`PLANNING_DIR` : résoudre `$PLANNING_DIR` (racine ou `.planning/workstreams/<ws>/`) avant de
construire `$f`, jamais un chemin littéral concaténé en dur une seconde fois.

**Docstring contractuelle à répliquer** (lignes 1-45) — forme obligatoire pour tout nouveau gate
créé dans cette phase (le gate d'activation doc↔capability, le gate sur le pointeur de session) :
- un rôle en une phrase citant l'ADR/SIG qui le justifie ;
- des états mutuellement exclusifs numérotés, dans l'ordre d'évaluation, avec leur exit code en
  face ;
- une section « Usage » + « Defaults » ;
- une section « Env » listant les variables de surcharge ;
- une section « Exit codes » qui énumère CHAQUE code (jamais implicite).

---

### `plugin/conductor/scripts/check-state-integrity.sh:53` (gate, request-response)

**Analogue :** lui-même — le chemin en dur à généraliser :
```bash
FILE_REL=".planning/STATE.md"
```
déjà surchargeable en CLI par `--file` (lignes 44-46) :
```bash
    --file)
      [ "$#" -ge 2 ] || { echo "[check-state-integrity] --file nécessite une valeur" >&2; exit 64; }
      FILE_REL="$2"; shift 2 ;;
```
→ Le rendre workstream-aware = ajouter une résolution automatique du sous-chemin workstream
(`.planning/workstreams/<ws>/STATE.md`) AVANT ce défaut, en conservant `--file` comme
surcharge explicite prioritaire — jamais l'inverse (une surcharge explicite ne doit jamais être
ré-écrasée par une auto-détection).

**Codes de sortie observés (à répliquer sur tout gate touché par la zone 5)** :
```
Codes de sortie : 0 = conforme · 1 = régression ou invariant rompu (message stderr précise lequel)
                  2 = erreur d'intégrité (hors dépôt git, fichier/ref illisible, champ imparsable)
                  64 = usage
```

**Le « jamais de repli faible » — exemple exact à citer dans le plan** (lignes 76-79) :
```bash
if ! git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[check-state-integrity] $ROOT hors d'un dépôt git — intégrité non vérifiable" >&2
  exit 2
fi
```
→ Le gate NE RETOMBE JAMAIS sur « conforme par défaut » quand il ne peut pas vérifier : il sort en
`2` (« non vérifiable »), jamais en `0`. C'est le patron imposé pour le gate créé sur le pointeur
de session workstream : si le pointeur `os.tmpdir()/gsd-workstream-sessions/...` est illisible ou
absent, le gate doit sortir KO « non vérifiable », jamais vert par défaut.

---

### `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — extension du gate T14

**Analogue :** le bloc T14 lui-même (`:1289-1321`), forme à répliquer pour ajouter
`graphify`/`gsd-profile-user` :

```bash
t14_fail=0
if [ ! -f "$ROUTING" ]; then
  ko "T14 exhaustivité : $ROUTING introuvable"; t14_fail=$((t14_fail+1))
else
  routed_count=$("$GREP" -Eo 'gsd-[a-z0-9-]+' "$ROUTING" | sort -u | wc -l | tr -d ' ')
  if [ "${routed_count:-0}" -lt 30 ]; then
    ko "T14 exhaustivité : la carte ne route que $routed_count brique(s) gsd-* (<30 — carte vidée ?)"
    t14_fail=$((t14_fail+1))
  fi
  ...
  INTENTIONALLY_UNROUTED="gsd-next gsd-mempalace-capture gsd-mempalace-recall"
  is_intentionally_unrouted() {
    case " $INTENTIONALLY_UNROUTED " in *" $1 "*) return 0 ;; esac
    return 1
  }
```

→ Le plancher anti-test-vacant (`routed_count -lt 30`) et la liste blanche
`INTENTIONALLY_UNROUTED` sont le patron exact pour distinguer « routé mais inerte » (`graphify`,
`gsd-profile-user`) de « intentionnellement non routé » : ajouter une nouvelle catégorie
(`ROUTED_BUT_INACTIVE` ou équivalent) suivant la même forme de liste blanche + fonction `case`,
jamais une variable booléenne éparse.

**Discriminance par mutation — patron à citer et répliquer, `test-check-gsd-config.sh:1210-1225`** :
```bash
#   - la mutation doit avoir CHANGÉ le fichier (comparaison par `cmp`, jamais par `diff`) ;
mutant() { # <nom> <cas devant rougir, vides = aucun> <fichier awk de mutation> <intention>
  ...
      ko "MUT $nom — $intention" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"; return
```
→ Preuve de discriminance exigée sur le nouveau cas T14 étendu ET sur le gate d'activation
doc↔capability créé : muter `gsd-capabilities-index.md` pour y faire disparaître l'état
`graphify: false`, prouver que le gate rougit, puis rejouer la réécriture licite (ex. l'index
régénéré normalement) et prouver qu'il redevient vert. Ne jamais se contenter d'un cas qui teste
seulement l'état nominal.

---

### `plugin/conductor/AGENT.md:114` — Iron Law 2

**Forme actuelle du bloc à réviser** (lignes 111-117) :
```markdown
## Iron Laws

1. **Je configure et garde le lab ; je ne fais pas le travail métier.**
2. **Router, jamais réimplémenter.**
3. **Détecter et proposer ; jamais corriger/migrer sans validation humaine** (ADR-031).
4. **Tout lab embarque ses auditeurs** — pas de configuration sans filet.
```
→ Contrainte du verdict zone 5 : réviser explicitement l'item 2 (ou ajouter une clause d'exception
nommée, citant l'ADR d'adoption workstreams créé par cette phase) — jamais la contourner en
silence. Toute Iron Law du dépôt est numérotée, en gras, une phrase, avec renvoi ADR entre
parenthèses quand elle s'appuie sur un arbitrage écrit (voir item 3 → `(ADR-031)`) : suivre ce même
gabarit pour la révision.

---

### `docs/ADR.md` — nouvelles entrées à partir d'ADR-066

**Analogue :** ADR-063 (`:1288-1331`) — entrée complète la plus récente avant ADR-064/065, forme à
répliquer littéralement :

```markdown
## ADR-063 : Anomalie d'agrégation `.planning/STATE.md` — dette d'artefact locale + bug amont non scopé, gate local, jamais de correction par `gsd-tools state`

**Date** : 2026-07-31
**Statut** : Validée
**Décideur** : Samuel (arbitrage de cadrage, mission delta `@opengsd/gsd-core` 1.8.0 → 1.9.0, Phase
VFDO-21 plan 21-04)
**Contexte** : ...

### Problème

...

### Diagnostic — deux causes distinctes, jamais confondues

...
```

**Structure obligatoire pour chaque ADR-066+ de cette phase** : titre `## ADR-0NN : <titre court
décisif>`, puis un bloc `**Date**` / `**Statut**` / `**Décideur**` / `**Contexte**`, puis des
sous-sections `###` narratives (`Problème`, `Diagnostic`, etc. — noms libres selon le sujet). Les
décideurs à citer pour cette phase : « Samuel (arbitrage `24-ARBITRAGES.md`, zone N) ». Chaque
entrée doit citer les fichiers et lignes réels examinés (aucune supposition), à l'image de
`state.cjs:1494-1501`, `plan-scan.cjs:158` dans ADR-063.

**Sujets à couvrir, un ADR par zone tranchée (au minimum) :**
- refus de `hooks.community` (zone 2, incompatibilité de style mesurée) ;
- refus des profils de contexte `context_profile` (zone 4, jamais « dépréciée ») ;
- révision de l'Iron Law 2 / adoption des workstreams (zone 5) — avec limites DATÉES ;
- montée de `@opengsd/gsd-core` au-delà de 1.9.1 comme prérequis dur (zone 2, issue #2893).

---

### `plugin/dev-orchestrator/references/gsd-capabilities-index.md` (index généré)

**Analogue :** lui-même — patron déjà établi en Phase 23 (D-07) : « tout index exposé est généré
depuis le disque ou gaté », matérialisé par le générateur `build-gsd-index.sh` →
`gsd-skills-index.md`.

→ Étendre `gsd-capabilities-index.md` à `graphify` et `profile-pipeline` DOIT suivre la même
mécanique de génération (pas d'édition manuelle de la table) : localiser le script générateur
existant pour cet index précis, y ajouter les deux capabilities en lisant leur état depuis
`capability-registry.cjs`/`config.json`, jamais les coder en dur dans le markdown.

---

### `.github/workflows/ci.yml` — extension aux chemins workstream

**Analogue :** le job `tests` existant (`:11-40`), principe explicite en tête de fichier :

```yaml
# Principe (contrat de découverte, F13) : chaque job ASSERTE que sa découverte est non vide
# avant de rendre un verdict — 0 suite trouvée ou 0 dossier d'agents trouvé = échec, jamais
# un vert par absence de cible (« vacuous green »).
```

→ Toute extension de la CI aux chemins workstream doit conserver ce contrat : si le job cherche
des workflows/agents sous `.planning/workstreams/**`, il doit échouer bruyamment si la découverte
est vide plutôt que passer en vert silencieux (même patron « jamais de repli faible » que les
gates bash).

---

## Shared Patterns

### Structure d'un gate bash de ce dépôt (check-*.sh)
**Source :** `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` (241 lignes),
`plugin/conductor/scripts/check-state-integrity.sh` (192 lignes)
**S'applique à :** le gate d'activation doc↔capability (créé), le gate sur le pointeur de session
workstream (créé), toute modification de `check-dev-bootstrap.sh`/`check-state-integrity.sh`.

Éléments constants dans les deux fichiers, à reproduire :
1. `set -uo pipefail` en tête (jamais `set -e` seul).
2. Docstring en commentaire de tête : rôle → états mutuellement exclusifs numérotés avec exit code
   en face → Usage/Defaults → Env → Exit codes (chaque code énuméré).
3. Boucle d'arguments `while [ "$#" -gt 0 ]; do case "$1" in ... esac; done` avec un gate `-h/--help`
   qui fait `grep '^# ' "$0" | sed 's/^# //'` (auto-documentation depuis les commentaires de tête).
4. Toute option qui attend une valeur vérifie `[ "$#" -ge 2 ]` (ou `${2:?msg}`) AVANT de consommer
   — jamais un `shift 2` qui boucle à l'infini sur une valeur absente.
5. Messages d'erreur préfixés `[nom-du-script] ` sur stderr.
6. Codes de sortie disjoints avec sémantique fixe dans ce dépôt : `0` = conforme/signalé,
   `1` = échec constaté, `2` = intégrité/vérifiabilité compromise, `3` = silence (rien à signaler),
   `64` = erreur d'usage.

### Le gate ne se replie jamais sur un vert par défaut
**Source :** `plugin/conductor/scripts/check-state-integrity.sh:76-79`
```bash
if ! git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[check-state-integrity] $ROOT hors d'un dépôt git — intégrité non vérifiable" >&2
  exit 2
fi
```
**S'applique à :** tout gate créé dans cette phase (activation doc↔capability, pointeur de
session). Dès qu'une vérification devient impossible (fichier absent, format illisible, JSON
imparsable), le gate sort en échec « non vérifiable » — jamais en `0` par défaut. Autre
occurrence de la même discipline : `check-dev-bootstrap.sh` bascule en silence total (D-04) plutôt
que d'inventer un état quand la liste blanche `^[0-9A-Za-z._ /-]{1,80}$` échoue sur le frontmatter
de `STATE.md`.

### Preuve de discriminance par mutation
**Source :** `plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh:1210-1225`
```bash
#   - la mutation doit avoir CHANGÉ le fichier (comparaison par `cmp`, jamais par `diff`) ;
mutant() { # <nom> <cas devant rougir, vides = aucun> <fichier awk de mutation> <intention>
  ...
      ko "MUT $nom — $intention" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"; return
```
**S'applique à :** toute extension de `test-dev-orchestrator.sh` (T14), tout nouveau gate créé.
Le cas de test doit : (1) muter l'artefact pour prouver le rouge, en vérifiant par `cmp` que la
mutation a bien changé le fichier (jamais `diff`, proxifié et menteur ici) ; (2) rejouer une
réécriture licite pour prouver que le gate redevient vert. Un cas qui ne teste que l'état nominal
n'est pas recevable dans ce dépôt.

### Frontmatter d'agent avec `effort:`
**Source :** `plugin/reference/content/methodology/templates/agents/business-agent-template.md:1-9`
```yaml
---
name: business-agent-[DOMAINE]
description: ...
model: sonnet
effort: medium
skills:
  - [SKILL_DOMAINE_1]
memory: project
---
```
**S'applique à :** les ~25 fichiers `plugin/*/agents/*.md`. Position observée : `effort:` entre
`model:` et `skills:`/`memory:`. Valeurs validées par `check-agents.sh:163`
(`EFFORT = {"low", "medium", "high", "xhigh", "max"}`).

### Forme d'une entrée ADR
**Source :** `docs/ADR.md` ADR-063 (`:1288`), ADR-064 (`:1459`)
```markdown
## ADR-0NN : <titre court, décisif>

**Date** : YYYY-MM-DD
**Statut** : Validée
**Décideur** : Samuel (arbitrage ..., référence de mission/phase)
**Contexte** : ...

### Problème
...
### Diagnostic ...
...
```
**S'applique à :** toute nouvelle entrée à partir d'ADR-066.

## No Analog Found

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| Texte de remontée amont (gabarit issue #2598) | doc narratif | — | Pas de gate ni de script analogue dans ce dépôt ; forme à tirer directement de l'issue #2598 elle-même (précédent amont cité par le cadrage) et du mémo de mission `2026-07-31-mesure-m2-dispatch-parallele.md` (voie 2), tous deux hors du périmètre « code du dépôt » que ce mapping couvre. |

## Metadata

**Analog search scope :** `plugin/conductor/scripts/`, `plugin/dev-orchestrator/scripts/`,
`plugin/dev-orchestrator/scripts/tests/`, `plugin/planning-core/scripts/`,
`plugin/reference/content/methodology/templates/agents/`, `plugin/dev-orchestrator/agents/`,
`docs/ADR.md`, `.github/workflows/ci.yml`, `.planning/config.json`.
**Files scanned :** ~15 fichiers lus en profondeur (offsets ciblés sur les fichiers > 200 lignes :
`test-dev-orchestrator.sh` 5727 lignes, `docs/ADR.md` 1551 lignes) + recherches `grep`/`awk` ciblées.
**Pattern extraction date :** 2026-08-04
