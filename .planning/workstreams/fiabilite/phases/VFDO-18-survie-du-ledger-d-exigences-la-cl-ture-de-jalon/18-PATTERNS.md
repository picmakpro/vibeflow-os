# Phase 18: Survie du ledger d'exigences à la clôture de jalon - Pattern Map

**Mapped:** 2026-08-17
**Files analyzed:** 7 (2 nouveaux scripts + 1 fichier de tests + hooks.json + AGENT.md + VERSION/CHANGELOG/README + config.json)
**Analogs found:** 6 / 7 (le rattrapage post-clôture — "reconstitution" — n'a pas d'analogue exact, il compose deux primitives existantes)

Pas de RESEARCH.md pour cette phase (recherche écartée par mandat) — CONTEXT.md porte déjà les
analogues exacts (section `<code_context>` / `<canonical_refs>`), ce mapping les concrétise en
excerpts.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/dev-orchestrator/scripts/check-requirements-survival.sh` | utility (gate SessionStart) | request-response (lecture d'état, un shot) | `plugin/dev-orchestrator/scripts/check-doc-drift.sh` | exact (même forme : gate SIG-0x, exit 0/3/64, `hook_exit`, `say`, `git_safe`) |
| `plugin/dev-orchestrator/scripts/tests/test-check-requirements-survival.sh` | test | batch (fixtures + assertions) | `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` | exact (même harness, même repo de tests) |
| primitive de détection partagée (nom à trancher au plan — ex. `requirements-survival-detect.sh`, sourcé) | utility (lib partagée) | transform (lecture MILESTONES.md + REQUIREMENTS.md → verdict) | `plugin/dev-orchestrator/scripts/workstream-policy.sh` (sourcé par `check-dev-bootstrap.sh` — voir lignes 133-172) | role-match (même pattern : script sourcé par plusieurs consommateurs, retour par variables `VF_*` + codes de sortie) |
| geste de rattrapage (reconstitution du ledger depuis l'archive — nom à trancher, probablement une commande ou un script invoqué sous confirmation) | utility (post-traitement, file-I/O) | file-I/O (lecture archive verbatim → écriture `.planning/REQUIREMENTS.md` reconstruit) | aucun analogue direct dans le module — le plus proche par la forme "propose un geste sous confirmation" est le triplet `[bootstrap]`/`[onboard]`/`[doc-drift]` de `check-dev-bootstrap.sh` / `check-doc-drift.sh`, mais ceux-ci ne font QUE proposer, jamais exécuter de rattrapage eux-mêmes | no-analog (composition nouvelle, cf. section dédiée) |
| `plugin/dev-orchestrator/hooks/hooks.json` (entrée SessionStart supplémentaire) | config (hook wiring) | event-driven | lui-même (fichier à modifier, pas un nouveau fichier) | exact — patron déjà appliqué 4 fois dans le même fichier |
| `plugin/dev-orchestrator/AGENT.md` (ligne de doctrine D-18-14) | config/doctrine (markdown) | transform (doc statique) | section `## Signaux de démarrage` existante (lignes 118-131) du même fichier | exact — table à étendre d'une ligne, même structure |
| `plugin/dev-orchestrator/VERSION` + `CHANGELOG.md` + `README.md` | config (release) | batch (bump versionné) | dernière entrée `CHANGELOG.md` (v2.18.0, 2026-08-17) | exact — patron de bump déjà appliqué à chaque phase du module |

## Pattern Assignments

### `plugin/dev-orchestrator/scripts/check-requirements-survival.sh` (utility, request-response)

**Analog:** `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (167 lignes)

**En-tête / doctrine du script** (lignes 1-61 de l'analogue) — à répliquer intégralement dans la
forme (rôle = "répondre au FAIT, jamais au métier", ADR-055 §3), en l'adaptant au signal SIG
propre à cette phase :
```bash
#!/usr/bin/env bash
# check-doc-drift.sh — La documentation a-t-elle suivi le code ? (SIG-03)
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne dit JAMAIS que la doc est
# fausse ou périmée — seulement qu'elle N'A PAS BOUGÉ depuis N commits de code. C'est le jugement
# de l'agent (ou de l'utilisateur) de décider si cette absence de mouvement est un problème réel.
```
Pour `check-requirements-survival.sh`, le pendant exact de ce refus doctrinal est **D-18-10** :
"le gate est lecteur d'absence, jamais juge de contenu" — une trace `carried-from:` malformée
n'est jamais un FAIL, elle tombe dans l'issue "imparsable" (BRUYANT, cf. QUAL-01 amendé Phase 32).

**Parsing d'arguments + gate de mutuelle exclusion `--hook`/`--quiet`** (lignes 62-95) :
```bash
set -uo pipefail
shopt -s nullglob

ROOT="."
THRESHOLD="20"
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-doc-drift] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --threshold)
      ...
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-doc-drift] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique (même position que le gate --path).
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-doc-drift] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi
```
`check-requirements-survival.sh` n'a probablement pas besoin de `--threshold` (D-18-10 : détection
d'absence binaire, pas de seuil) mais garde `--path`, `--hook`, `--quiet` à l'identique.

**`hook_exit()` — traduction du silence interne vers le harness** (lignes 107-118, IDENTIQUE mot
pour mot à copier) :
```bash
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" -eq 1 ] && [ "$code" -eq 3 ]; then
    exit 0
  fi
  exit "$code"
}
```

**`git_safe()` — durcissement git (T-17-06), OBLIGATOIRE dès qu'un script shell-out vers git**
(lignes 120-129, IDENTIQUE à copier) :
```bash
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0

git_safe() { # <args...> — toute invocation git de ce script passe par ici, jamais un appel nu.
  git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"
}
```
Note : `check-requirements-survival.sh` n'a probablement pas besoin de git (il lit `MILESTONES.md`
et `REQUIREMENTS.md` sur disque, pas l'historique) — mais si le rattrapage doit dater l'archive
consommée (`milestones/v[X.Y]-REQUIREMENTS.md`), le même wrapper s'applique par précaution.

**Structure de sortie du signal** (lignes 159-167, patron à reproduire pour le signal propre à la
phase, ex. `[requirements-missing]`) :
```bash
if [ "$COUNT" -ge "$THRESHOLD" ]; then
  say "seuil atteint : ..."
  printf '%s\n' "[doc-drift] ${COUNT} commits de code depuis la dernière mise à jour de la doc."
  printf '%s\n' "            → propose gsd-docs-update."
  exit 0
fi

say "..."
hook_exit 3
```

**Codes de sortie (contrat interne, à documenter à l'identique dans l'en-tête)** :
```
0  = signal émis
3  = rien à signaler
64 = argument inconnu / valeur manquante / --hook + --quiet ensemble
```

---

### `plugin/dev-orchestrator/scripts/tests/test-check-requirements-survival.sh` (test)

**Analog:** `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` (278 lignes)

Ratio observé sur l'analogue exact : 278/167 ≈ 1,66× — le CONTEXT.md (§Established Patterns)
signale ce chiffre comme plus fiable que celui du STUDY (1,5×, daté). Prévoir ~170-250 lignes de
tests pour un gate de 100-150 lignes.

Structure de fixtures attendue (à confirmer en lisant le fichier au moment du plan, non relu ici
pour éviter la duplication de contexte — il a déjà été identifié comme analogue exact dans
CONTEXT.md) : dépôt jetable par test (`mktemp -d` + `git init`), assertions sur stdout/stderr/exit
code séparément, un test par état (silence hors dépôt, silence nominal, signal émis, argument
invalide, mutuelle exclusion `--hook`/`--quiet`).

Pour `check-requirements-survival.sh`, les états à fixturer découlent directement de D-18-08 à
D-18-13 : jalon clos + ledger présent (silence), jalon clos + ledger absent (signal), jalon non
clos (silence quel que soit l'état du ledger), trace `carried-from:` bien formée vs malformée
(D-18-10 : jamais FAIL, toujours BRUYANT sur malformé).

---

### Primitive de détection partagée (nom à trancher au plan)

**Analog:** `plugin/dev-orchestrator/scripts/workstream-policy.sh`, sourcé par
`check-dev-bootstrap.sh` lignes 133-172.

**Pattern de découverte + sourcing d'un script partagé** (lignes 133-137 de
`check-dev-bootstrap.sh`) :
```bash
WS_POLICY=""
for _cand in "$(dirname "$0")/workstream-policy.sh" \
             "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
  [ -r "$_cand" ] && { WS_POLICY="$_cand"; break; }
done
```

**Pattern d'appel + retour par variables `VF_*` + code de sortie discriminant** (lignes 145-172) :
```bash
if [ -z "$WS_POLICY" ]; then
  say "workstream-policy.sh introuvable — aucun compartiment résolu, lecture sur la racine."
else
  # shellcheck source=/dev/null
  . "$WS_POLICY"
  vf_ws_resolve "$PLANNING_DIR" "${VF_BOOTSTRAP_WORKSTREAM:-}"; ws_rc=$?
  if [ "$ws_rc" -eq 2 ]; then
    say "workstream rejeté par la politique amont ($VF_WS_REASON, canal $VF_WS_SOURCE) — ..."
  elif [ -n "$VF_WS_NAME" ]; then
    ...
  fi
fi
```

Application à la phase 18 : la primitive partagée doit exposer une fonction (ex.
`vf_requirements_missing_after_close`) qui lit `.planning/MILESTONES.md` (dernier jalon déclaré
clos) et `.planning/REQUIREMENTS.md` (présence/absence), et retourne un code discriminant (0 =
absent après clôture, 1 = présent ou pas de clôture, 2 = état illisible → BRUYANT). Le gate
(`check-requirements-survival.sh`) ET le rattrapage la sourcent tous les deux — jamais de logique
de détection dupliquée entre les deux consommateurs (cf. CONTEXT.md §Specifics).

**Rôle "injecteur, fail-open mais jamais muet"** (lignes 146-148) — motif à répliquer si la
primitive elle-même est absente ou cassée :
```bash
# RÔLE INJECTEUR (hook SessionStart) : fail-open, mais JAMAIS muet. Un exit non nul ici
# dégraderait toutes les sessions ; un silence masquerait l'absence d'outillage.
say "workstream-policy.sh introuvable — aucun compartiment résolu, lecture sur la racine."
```

---

### `plugin/dev-orchestrator/hooks/hooks.json` (modification, event-driven)

**Analog:** lui-même — patron déjà appliqué à chaque entrée existante.

**Forme exec actuelle, forme exacte à répliquer pour la nouvelle entrée** :
```json
{ "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/check-doc-drift.sh", "--hook"] }
```
Rappel du hotfix v2.53.1 (mémoire projet + CONTEXT.md D-18-06) : la forme exec signifie **zéro
expansion shell** — jamais de `&&`, `||`, substitution de variable dans `command`, tout passe par
`args`. Les deux scopes (user/project) doivent être testés à l'armement.

Insertion : ajouter une ligne dans le tableau `"hooks"` du bloc `"matcher": "startup"`, à la suite
des 4 entrées existantes (check-dev-bootstrap, discover-unintegrated-docs, check-doc-drift,
check-gsd-config) — **avant** l'entrée `check-hook-paths.sh` qui garde une forme `"command": "bash"`
littérale et doit rester en dernier par construction (dérogation ADR-071 §Décision 2, documentée
dans la `description` du fichier).

**Dette connue à ne PAS rouvrir** (CONTEXT.md §Integration Points) : `merge-hooks.sh` porte un bug
d'idempotence cross-matcher, contourné en Phase 32 par une entrée unique dans ce même
`"matcher": "startup"`. Le plan doit composer avec cette contrainte (une seule entrée `matcher`,
toutes les commandes dans le même tableau `"hooks"`), pas la corriger.

**En-tête `description` du fichier** (ligne 2) — à étendre d'une clause décrivant le 6e signal,
même style de phrase que les 5 signaux déjà documentés :
```json
"description": "Signaux de démarrage du moteur de dev : état du bootstrap projet, documents de
cadrage orphelins de la feuille de route, dérive documentaire, alignement du .planning/config.json
sur le moteur GSD installé, et péremption des chemins de hook figés à l'install. ..."
```

---

### `plugin/dev-orchestrator/AGENT.md` (modification doctrine, D-18-14)

**Analog:** section `## Signaux de démarrage` du même fichier (lignes 118-131).

**Table de signaux existante, patron exact pour la nouvelle ligne** :
```markdown
| Signal | Geste proposé | Confirmation |
|---|---|---|
| `[bootstrap]` | `gsd-config` puis `gsd-map-codebase` (items manquants listés) | requise avant toute écriture (ADR-031) |
| `[onboard]` | `gsd-onboard` | requise avant toute écriture (ADR-031) |
| `[gsd-engine]` | oriente vers `gsd-discuss-phase` / `gsd-plan-phase` / `gsd-progress` — pas un correctif | orientation seule, rien à écrire |
| `[doc-drift]` | `gsd-docs-update --verify-only` d'abord (read-only), génération ensuite — doctrine `docs-flow.md` | requise avant toute écriture (ADR-031) |
```
Ajouter une ligne `[requirements-missing]` (ou le nom de signal retenu au plan) → geste de
rattrapage → confirmation requise (ADR-031, cf. D-18-06 "sous validation humaine, jamais en
silence").

La ligne de doctrine D-18-14 elle-même (archives = instantanés, `.planning/REQUIREMENTS.md` =
seule source vivante) n'a pas d'emplacement structurel préexistant dans `AGENT.md` — le plan doit
choisir entre l'ajouter à la table des signaux (comme note sous la table, même patron que la note
existante ligne 120-123 "Un 5e fait ... est déjà couvert par ...") ou une nouvelle sous-section
courte. Respecter le plafond ADR-029 (250 lignes, cf. précédent CHANGELOG v2.18.0 : "aucune ligne
neuve" quand le plafond est déjà tendu).

---

### `plugin/dev-orchestrator/VERSION` + `CHANGELOG.md` + `README.md` (release)

**Analog:** dernière entrée du `CHANGELOG.md` du module (v2.18.0, 2026-08-17).

**Patron d'entrée CHANGELOG** (format exact à répliquer) :
```markdown
## [v2.18.0] — 2026-08-17 (annexe notifications — D-33-H Q6, Pattern H)

**Minor** (nouvelle capacité publique : doctrine des jalons GSD vers l'app Claude).

- `references/mission-flow.md` : nouveau `Pattern H — ...`. Documente ...
- `agents/vf-dev-manager.md` : renvoi d'une clause vers ...
```
Version actuelle : `v2.18.0`. Nouvelle capacité publique (gate + rattrapage + doctrine) → **minor**
selon la convention `CLAUDE.md` racine ("nouveau module / nouvelle capacité → minor"). Bump attendu
vers `v2.19.0`, à synchroniser avec `plugin/.claude-plugin/plugin.json` et
`.claude-plugin/marketplace.json` si une release racine accompagne la phase (cf. règle de tag du
`CLAUDE.md` racine).

## Shared Patterns

### Gate SessionStart / SIG-0x (forme du module dev-orchestrator)
**Source:** `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (structure complète) +
`plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` (multi-états + frontmatter sécurisé)
**Apply to:** `check-requirements-survival.sh`
- `set -uo pipefail` + `shopt -s nullglob` en tête
- parsing d'arguments avec gate `--hook`/`--quiet` mutuellement exclusifs, position identique
- `say()` conditionné à `QUIET`
- `hook_exit()` : traduction 3→0 uniquement sous `--hook`, jamais pour 0/64
- `-h|--help` : `grep '^# ' "$0" | sed 's/^# //'` (auto-documentation depuis l'en-tête commenté)
- signal sur stdout en 2 lignes (`[tag] constat.` puis `            → geste proposé.`), diagnostics
  humains sur stderr via `say`

### Durcissement git (T-17-06)
**Source:** `plugin/dev-orchestrator/scripts/check-doc-drift.sh` lignes 120-129
**Apply to:** tout script de la phase qui shell-out vers git (probablement le rattrapage, pour
dater/vérifier l'archive consommée)
```bash
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }
```

### Sourcing d'un script partagé entre plusieurs consommateurs
**Source:** `plugin/dev-orchestrator/scripts/workstream-policy.sh`, sourcé par
`check-dev-bootstrap.sh` (lignes 133-172)
**Apply to:** la primitive de détection partagée entre `check-requirements-survival.sh` et le
geste de rattrapage (CONTEXT.md : "une primitive, deux consommateurs — à exploiter au plan plutôt
qu'à dupliquer")
- découverte du script par une liste de chemins candidats (`for _cand in ...`)
- sourcing (`. "$WS_POLICY"`) + appel de fonction + code de sortie discriminant, jamais de parsing
  de sortie texte entre les deux scripts
- retour par variables `VF_*` préfixées, jamais par écriture de fichier temporaire

### Ratchet (armement progressif d'un gate)
**Source:** `.planning/config.json` clé `workflow.windows_enforce` (précédent cité par
`docs/ADR.md` ADR-066, lignes 1566-1606) — booléen simple qui active/désactive un gate déjà codé,
posé après vérification de non-régression sur une copie jetable avant d'être joué pour de vrai.
**Apply to:** D-18-08 (ratchet de `check-requirements-survival.sh`) — la forme retenue par
l'ADR-066 est une **clé booléenne dans `.planning/config.json`**, pas un fichier de marqueur
séparé ni une variable d'environnement. À confirmer au plan contre le comportement exact de
`workflow.windows_enforce` (où est-il lu ? par quel gate ? quel est le comportement par défaut
absent = avertit, présent+true = bloque ?) — non entièrement tracé dans ce mapping, le plan doit
lire `hooks.workflow_guard` / le consommateur de cette clé pour confirmer la mécanique avant de la
répliquer.

### Confirmation humaine avant écriture (ADR-031)
**Source:** `check-dev-bootstrap.sh` (3 signaux `[onboard]`/`[bootstrap]`/`[doc-drift]`, aucun
n'exécute — tous impriment "→ propose X (confirmation requise)")
**Apply to:** le geste de rattrapage (D-18-06 : "propose la reconstitution sous validation
humaine, jamais en silence")

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Geste de rattrapage (reconstitution du ledger depuis l'archive) | utility, post-traitement | file-I/O | Aucun script du module ne fait de reconstruction de fichier depuis une archive verbatim + réinjection de trace `carried-from:`. C'est une composition nouvelle : lire l'archive `milestones/v[X.Y]-REQUIREMENTS.md`, appliquer la table statut→destin (D-18-11), écrire `.planning/REQUIREMENTS.md` avec section `## Garanties` + items voyageurs tracés. Le plan doit concevoir cette logique de zéro, mais en respectant strictement l'Iron Law 2 (router, jamais réimplémenter `complete-milestone`/l'archivage/la génération — CONTEXT.md D-18-05) : ce script ne touche jamais à l'archive elle-même (lecture seule), ne régénère jamais de ROADMAP, ne fait que composer un `REQUIREMENTS.md` vivant à partir de ce qui existe déjà sur disque. |

## Metadata

**Analog search scope:** `plugin/dev-orchestrator/scripts/`, `plugin/dev-orchestrator/scripts/tests/`,
`plugin/dev-orchestrator/hooks/`, `plugin/dev-orchestrator/AGENT.md`, `plugin/dev-orchestrator/{VERSION,CHANGELOG.md}`,
`.planning/{REQUIREMENTS.md,MILESTONES.md}`, `docs/ADR.md` (ADR-066, précédent ratchet)
**Files scanned:** 8 (check-doc-drift.sh, check-dev-bootstrap.sh, hooks.json, AGENT.md, CHANGELOG.md,
VERSION, REQUIREMENTS.md, MILESTONES.md) + grep ciblé sur `windows_enforce` dans ADR.md
**Pattern extraction date:** 2026-08-17
</content>
