---
phase: VFDO-17-signaux-de-d-marrage-du-moteur-de-dev
plan: 02
subsystem: dev-tooling
tags: [bash, git, hooks, session-start, dev-orchestrator, doc-drift, docs-ingest]

# Dependency graph
requires:
  - phase: VFDO-17-01
    provides: patron composite (shebang/header/arg-loop/say()/mktemp+trap/contrat 0-3-64), fragment hooks/hooks.json déjà posé référençant les 3 commandes
  - phase: VFDO-13-pont-spec-feuille-de-route
    provides: discover-unintegrated-docs.sh (contrat historique grain\tchemin à ne jamais casser)
provides:
  - check-doc-drift.sh — dérive documentaire, heuristique git, seuil réglable --threshold (défaut 20)
  - discover-unintegrated-docs.sh --hook — agrégation en une ligne [docs-ingest], additive
  - suite test-check-doc-drift.sh (21 assertions, frontière seuil-1/seuil/seuil+1 nommée)
  - suite test-discover-unintegrated-docs.sh étendue (16 cas historiques inchangés + 6 cas 17-22)
  - 3e commande du fragment hooks/hooks.json (posé en 17-01) désormais vivante : check-doc-drift.sh existe
affects: [VFDO-17-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Premier appel à git dans plugin/**/scripts/ : wrapper unique git_safe() durcissant chaque invocation (core.fsmonitor=, core.hooksPath=/dev/null, --no-optional-locks) + 3 variables d'environnement exportées en tête de script — un dépôt cloné non maîtrisé ne peut pas faire exécuter un programme via sa propre configuration au SessionStart"
    - "Pathspec git 'README*' (sans wildcard sur slash) nativement ancré à la racine du dépôt : un chemin qui ne commence pas littéralement par 'README' ne matche jamais, donc plugin/*/README.md est exclu par construction — vérifié empiriquement avant écriture du script, pas supposé"
    - "Décompte de commits via git rev-list --count (ensemble d'ancêtres borné par le graphe), jamais une liste triée par horodatage — déterminisme garanti même si deux commits partagent le même timestamp"
    - "Extension additive à 2 points d'insertion identifiés à la ligne près (boucle d'arguments + branche de sortie), preuve de non-régression par comparaison octet pour octet avec git show HEAD:<chemin> plutôt qu'une relecture visuelle"

key-files:
  created:
    - plugin/dev-orchestrator/scripts/check-doc-drift.sh
    - plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh
  modified:
    - plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh
    - plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh

key-decisions:
  - "--hook ne modifie aucun rendu pour check-doc-drift.sh (même choix que check-dev-bootstrap.sh en 17-01) : ce script n'a qu'un seul gabarit de signal ([doc-drift], 2 lignes) — --hook ne sert qu'à la parité d'interface avec les deux autres scripts et au gate de mutuelle exclusion avec --quiet."
  - "Aucun mktemp utilisé dans check-doc-drift.sh (contrairement au patron de discover-unintegrated-docs.sh) : le script ne construit aucun fichier intermédiaire — un seul SHA et un seul compte, capturés directement dans des variables. Satisfait D-15 (aucune écriture hors mktemp) trivialement, puisqu'aucune écriture filesystem n'a lieu du tout."
  - "Le SHA de départ (dernier commit touchant docs/ ou README* racine) est trouvé avec le MÊME pathspec ('docs' 'README*') que celui utilisé pour l'exclusion du décompte ultérieur (':!docs' ':!README*') — garantit que le point de départ et les chemins exclus du décompte sont exactement les mêmes chemins de doc, condition explicite de D-07."
  - "Pas de fixture Docker/CI ajoutée : la preuve de portabilité Linux (D-13) a été faite en exécutant les 3 suites (dont la nouvelle et l'étendue) dans un conteneur debian:bookworm-slim avant ce commit — reproductible, non committée comme artefact (résultat documenté ci-dessous)."

patterns-established:
  - "Pattern : premier point d'appel git d'un module dev-orchestrator, durci systématiquement par un wrapper unique — réutilisable tel quel par tout futur script du module qui aurait besoin de git."

requirements-completed: [SIG-02, SIG-03]

coverage:
  - id: D1
    description: "check-doc-drift.sh constate la dérive documentaire (heuristique git, seuil réglable --threshold, défaut 20) avec le contrat de sortie 0/3/64"
    requirement: "SIG-03"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh#cas 4,5,6 (frontière seuil-1/seuil/seuil+1)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Silence hors dépôt git, sans commit de doc, ou dépôt à 0 commit — jamais de division par un historique vide"
    requirement: "SIG-03"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh#cas 1,2,3"
        status: pass
    human_judgment: false
  - id: D3
    description: "README de module exclu, README* racine inclus, commit mixte reparti le compteur à 0, déterminisme sur horodatages partagés"
    requirement: "SIG-03"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh#cas 12,13,14,18"
        status: pass
    human_judgment: false
  - id: D4
    description: "Durcissement git (T-17-06) réellement présent dans le code, pas seulement documenté"
    requirement: "SIG-03"
    verification:
      - kind: other
        ref: "grep -c 'core.fsmonitor=' plugin/dev-orchestrator/scripts/check-doc-drift.sh → 2"
        status: pass
    human_judgment: false
  - id: D5
    description: "discover-unintegrated-docs.sh --hook agrège en une ligne [docs-ingest], exits strictement inchangés"
    requirement: "SIG-02"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh#cas 17,18,19,20,22"
        status: pass
    human_judgment: false
  - id: D6
    description: "Non-régression du contrat historique grain<TAB>chemin — 16 cas préexistants inchangés, sortie du mode par défaut identique octet pour octet à la version précédente"
    requirement: "SIG-02"
    verification:
      - kind: other
        ref: "diff <(git show <parent>:.../discover-unintegrated-docs.sh --path .) <(bash discover-unintegrated-docs.sh --path .) ; git diff ne montre aucune modification des blocs cas 1-16"
        status: pass
    human_judgment: false

# Metrics
duration: ~35min
completed: 2026-07-27
status: complete
---

# Phase VFDO-17 Plan 02: Dérive documentaire + agrégation d'ingestion Summary

**`check-doc-drift.sh` (nouveau, premier appel git durci du module) et
`discover-unintegrated-docs.sh --hook` (extension additive prouvée non-régressive octet pour
octet) rendent vivante la 3e commande du fragment de hooks posé en 17-01 — les deux faits
restants du continuum de signaux sont désormais constatés.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-07-27T21:20:00Z
- **Tasks:** 2 (Task 1 TDD check-doc-drift.sh, Task 2 TDD extension additive)
- **Files modified:** 4 (2 créés, 2 étendus)

## Accomplishments

- `check-doc-drift.sh` : heuristique de commits de code depuis le dernier commit de doc
  (`docs/**` arbre entier ou `README*` **racine seulement** — les README de module sont exclus par
  construction, vérifié empiriquement avant écriture via le comportement natif du pathspec git
  `README*`, ancré au début du chemin). Seuil réglable `--threshold` (défaut 20), validé
  (`^[0-9]+$`, `0` accepté), frontière `seuil-1`/`seuil`/`seuil+1` couverte nommément. Décompte via
  `git rev-list --count` sur un ensemble d'ancêtres — déterministe même à horodatages identiques
  (prouvé par un cas dédié avec deux commits de doc au même timestamp).
- Durcissement git (T-17-06) : premier script de `plugin/**/scripts/` à shell-out vers git. Wrapper
  unique `git_safe()` appliquant `-c core.fsmonitor= -c core.hooksPath=/dev/null
  --no-optional-locks` à CHAQUE invocation, plus `GIT_CONFIG_NOSYSTEM=1`, `GIT_TERMINAL_PROMPT=0`,
  `GIT_OPTIONAL_LOCKS=0` exportés en tête de script — un dépôt cloné non maîtrisé ne peut donc pas
  faire exécuter un programme via sa configuration lors d'une lecture au `SessionStart`.
- `discover-unintegrated-docs.sh --hook` : extension strictement additive à 2 points d'insertion
  (boucle d'arguments + branche de sortie), une ligne agrégée `[docs-ingest] N documents… (X spec,
  Y plan)` remplaçant la liste, exits 0/3/64 rigoureusement inchangés. Non-régression prouvée
  **empiriquement**, pas par relecture : `diff` octet pour octet entre la sortie du mode par défaut
  et `git show HEAD~1:<chemin>` sur ce dépôt réel, et les 16 cas historiques de sa suite passent
  inchangés (confirmé par `git diff` — aucune modification dans leurs blocs).
- Les 3 suites (2 de ce plan + `test-check-dev-bootstrap.sh` de 17-01, non touchée) ont été
  rejouées avec succès dans un conteneur Linux (`debian:bookworm-slim`, bash 5.x, git de Debian) en
  plus de macOS — preuve de portabilité D-13 avant ce commit.

## Task Commits

Chaque tâche a été commitée atomiquement :

1. **Task 1 : `check-doc-drift.sh` + suite `test-check-doc-drift.sh`** — `2c6e520` (feat)
2. **Task 2 : `discover-unintegrated-docs.sh --hook` + extension de suite (cas 17-22)** —
   `10c5ec8` (feat)

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (153 lignes) — script de constat
  SessionStart, heuristique git, seuil réglable, contrat de sortie 0/3/64, lecture seule.
- `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` (232 lignes) — suite de 21
  assertions, fixtures git réelles (`git init` + commits scriptés, identité locale fixe).
- `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (168 lignes, +27/-1) — flag
  `--hook` additif, 2 points d'insertion (boucle d'arguments, branche de sortie).
- `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` (205 lignes, +57/-2) —
  6 cas 17-22 ajoutés après le cas 16 existant, 16 cas historiques strictement inchangés.

## Decisions Made

- **`--hook` sans effet de rendu sur `check-doc-drift.sh`** — même choix que `check-dev-bootstrap.sh`
  en 17-01 : ce script n'a qu'un seul gabarit de signal, `--hook` ne sert qu'à la parité
  d'interface et au gate `--hook`+`--quiet`.
- **Aucun `mktemp` dans `check-doc-drift.sh`** — le script ne construit aucun fichier intermédiaire
  (un SHA et un compte, capturés en variables), donc l'invariant « aucune écriture hors mktemp »
  (D-15) est satisfait trivialement, sans qu'un `mktemp`/`trap` soit nécessaire.
- **Même pathspec (`docs` `README*`) pour trouver le SHA de départ et pour l'exclusion du décompte
  ultérieur** (`':!docs' ':!README*'`) — garantit que le point de départ et les chemins exclus du
  décompte sont exactement les mêmes chemins de doc (condition explicite de D-07 du contexte de
  phase).
- **Preuve de portabilité par exécution réelle, pas par nouvelle fixture CI** — les 3 suites (dont
  celles de ce plan) ont été rejouées dans `debian:bookworm-slim` avant ce commit ; aucune
  modification de `.github/workflows/ci.yml` n'était nécessaire ni faite (découverte déjà
  générique, confirmée par le contexte de phase D-13).

## Deviations from Plan

**Aucune déviation de comportement.** Exécution conforme au plan sur les deux tâches, aucun
Rule 1-4 déclenché.

## Issues Encountered

Aucun. Le sandbox d'exécution a autorisé l'écriture sous le répertoire scratchpad de session pour
les fixtures de vérification manuelles préalables à l'écriture des suites (mêmes contraintes que
17-01 : `/tmp` en lecture seule dans le bac à sable, contournement documentaire seulement, n'affecte
aucun artefact livré).

## User Setup Required

None — aucune configuration de service externe requise.

## Next Phase Readiness

- Les 3 commandes du fragment `hooks/hooks.json` (posé en 17-01) pointent désormais toutes sur un
  script réel et fonctionnel : `check-dev-bootstrap.sh`, `discover-unintegrated-docs.sh`,
  `check-doc-drift.sh`.
- SIG-02 et SIG-03 tenus, en plus de SIG-01/SIG-04 déjà livrés en 17-01.
- Le plan 17-03 (doctrine agent `AGENT.md`, release-meta du module `v2.4.0` → `v2.5.0`, gate
  ADR-044 sur l'`AGENT.md` modifié) peut s'appuyer sur les 3 scripts et 3 suites désormais
  complets et verts (macOS + Linux).
- Aucun blocage identifié pour la suite de la phase.

---
*Phase: VFDO-17-signaux-de-d-marrage-du-moteur-de-dev*
*Completed: 2026-07-27*

## Self-Check: PASSED

- FOUND: plugin/dev-orchestrator/scripts/check-doc-drift.sh
- FOUND: plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh
- FOUND commit 2c6e520
- FOUND commit 10c5ec8
- `bash plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` → 21 ok, 0 ko
- `bash plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` → 22 ok, 0 ko
- `bash plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh` (plan 17-01, croisé) →
  23 ok, 0 ko — aucune régression croisée
- `git status --short` ne montre que les 2 chemins hors périmètre déjà non trackés avant exécution
  (`.planning/missions/dag-phase17.json`,
  `.planning/phases/VFDO-18-capability-living-specs-conventions-openspec/`), laissés intacts.
