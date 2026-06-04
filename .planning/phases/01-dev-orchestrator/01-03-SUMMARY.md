---
phase: 01-dev-orchestrator
plan: 03
subsystem: agent
tags: [agent, routing, gsd, superpowers, pipeline, density, nl]

# Dependency graph
requires:
  - "Module dev-orchestrator/ scaffoldé (Plan 01-01)"
  - "Index factuel gsd-skills-index.md généré (Plan 01-01)"
provides:
  - "Agent routeur vibeflow-dev (AGENT.md) : cerveau NL → action GSD/Superpowers (D4)"
  - "Doctrine pipeline déportée (references/GSD-PIPELINE.md) chargée on-demand"
  - "12 cibles canoniques de routage figées, partagées avec les verbes /vf-* (Plan 04)"
affects: [01-04, 01-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Frontmatter subagent natif Claude Code calqué sur validator/AGENT.md (name/description/model/memory)"
    - "Charte densité : corps d'agent ≤250L, détail déporté en référence on-demand (règle 1%)"
    - "Référencement de la doctrine via chemin d'install D7 absolu (.claude/agents/dev-orchestrator-references/) — jamais de relatif ambigu"
    - "Persona masquant : reframe systématique GSD/Superpowers → vocabulaire VibeFlow (sprint, feuille de route)"

key-files:
  created:
    - dev-orchestrator/AGENT.md
    - dev-orchestrator/references/GSD-PIPELINE.md
  modified: []

key-decisions:
  - "Table de routage = 14 occurrences distinctes matchées (≥11 requis) ; 12 cibles canoniques figées pour rester synchrone avec les verbes /vf-* du Plan 04"
  - "AGENT.md référence GSD-PIPELINE.md et gsd-skills-index.md via le chemin d'install D7 exact (.claude/agents/dev-orchestrator-references/), pas le chemin source repo dev-orchestrator/references/"
  - "Détail pipeline (chemin autonome, escape hatches, /clear, model profiles, garde-fous) déporté hors du corps de l'agent pour tenir la densité ≤250L (résultat : 125L)"
  - "gsd-new-project routé mais marqué interactif → proposé sur confirmation seulement (BOOT-04), jamais lancé seul ni en autonomie"
  - "model: opus pour vibeflow-dev (rôle de raisonnement/routage NL), aligné sur le profil planner"

patterns-established:
  - "Un agent routeur lean (≤250L) qui embarque l'ordre canonique en 1 bloc et délègue tout le détail à une référence on-demand"
  - "Masquage total de la plomberie : aucun nom de skill brut ni mention GSD/Superpowers côté utilisateur"

requirements-completed: [ROUT-01, ROUT-02, ROUT-03, ROUT-04]

# Metrics
metrics:
  duration: ~12 min
  tasks-completed: 2
  files-created: 2
  completed-date: 2026-06-04
---

# Phase 01 Plan 03 : Agent routeur vibeflow-dev Summary

Agent `vibeflow-dev` (routeur NL → action, 125L) + doctrine pipeline déportée : le cerveau (D4)
qui traduit le langage naturel en skill GSD/Superpowers sans jamais exposer la plomberie.

## Ce qui a été fait

### Task 1 — references/GSD-PIPELINE.md (doctrine déportée)
Doctrine pipeline chargée on-demand (117L) : ordre canonique
`new-project → map-codebase → discuss-phase → plan-phase → execute-phase → verify-work → code-review → ship → complete-milestone`
mappé sur les skills réels (table avec vocabulaire VibeFlow), chemin autonome (`gsd-autonomous`),
escape hatches (`gsd-quick`/`gsd-fast`), quand faire `/clear`, model profiles (planner/executor/checker),
et garde-fous (BOOT-04 : `gsd-new-project` interactif jamais lancé seul). Couvre ROUT-02.
- **Commit :** 880e7d2

### Task 2 — AGENT.md (vibeflow-dev, ≤250L)
Agent calqué sur `validator/AGENT.md`. Frontmatter subagent valide
(`name: vibeflow-dev`, `description` multiline FR, `model: opus`, `memory: project`).
Corps : persona masquant (reframe SUMMARY→rapport de sprint, ROADMAP→feuille de route, jamais « GSD »),
table de routage couvrant 12 cibles canoniques (14 occurrences distinctes matchées par le grep),
ordre canonique embarqué en 1 bloc + renvoi à la doctrine via le chemin d'install D7,
heuristiques de routage, garde-fous, Iron Laws et anti-patterns. 125 lignes. Couvre ROUT-01, ROUT-03, ROUT-04.
- **Commit :** cd05ffa

## Vérifications

- **Task 1** (`test -f … && grep new-project && grep autonomous && grep clear`) → exit 0.
- **Task 2** (frontmatter `^---` + `name: vibeflow-dev` + chemins D7 GSD-PIPELINE/gsd-skills-index
  + `wc -l ≤ 250` + comptage `grep -Eo | sort -u | wc -l ≥ 11`) → **exit 0, 14 cibles distinctes, 125 lignes**.
  - Note : la commande de verify est écrite pour bash + grep système. Le shell interactif de cet
    environnement (zsh) aliase `grep` vers un wrapper `ugrep -G` qui faisait échouer la chaîne `&&`
    de manière trompeuse ; ré-exécutée sous `/bin/bash -c` avec `command grep`, la vérification
    retourne exit 0. Le livrable lui-même est conforme (aucune modification de code requise).

## Couverture des requirements

- **ROUT-01** — ≥11 cibles de routage distinctes vers des skills réels : 14 (✓, vérifié par `grep -Eo | sort -u | wc -l`).
- **ROUT-02** — ordre pipeline embarqué + détail déporté dans GSD-PIPELINE.md, référencé via chemin D7 : ✓.
- **ROUT-03** — persona masque GSD, reframe en vocabulaire VibeFlow : ✓.
- **ROUT-04** — distribué via AGENT.md (installé en `.claude/agents/dev-orchestrator.md` par l'installeur) : ✓.

## Deviations from Plan

None - plan executed exactly as written. (Les deux tasks ont passé leur verify dès la première
exécution sous bash ; aucune correction Rule 1-4 n'a été nécessaire.)

## Known Stubs

Aucun. Les deux fichiers sont de la doctrine/agent en markdown — pas de source de données à câbler,
aucun placeholder UI.

## Self-Check: PASSED

- FOUND: dev-orchestrator/AGENT.md
- FOUND: dev-orchestrator/references/GSD-PIPELINE.md
- FOUND: .planning/phases/01-dev-orchestrator/01-03-SUMMARY.md
- FOUND commit: 880e7d2 (Task 1)
- FOUND commit: cd05ffa (Task 2)
