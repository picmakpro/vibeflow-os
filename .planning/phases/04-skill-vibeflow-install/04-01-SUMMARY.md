---
phase: 04-skill-vibeflow-install
plan: 01
subsystem: installer
tags: [skill, installer, scope, dependencies, jq, writing-skills]
requires:
  - "resolve-deps.sh (fermeture transitive — Phase 2)"
  - "vibeflow-update.sh --scope (engine scope-aware — Phase 3)"
  - "ensure-deps.sh (bootstrap GSD/Superpowers via VF_SCOPE — Phase 3)"
  - "les 8 module.json (Phase 2)"
provides:
  - "build-module-catalog.sh : catalogue nom+description agrégé depuis les module.json"
  - "installer/SKILL.md : skill /vibeflow-install orchestrateur à toggles"
affects:
  - "Phase 4 plan 02 (hook SessionStart 1er lancement qui invoquera ce skill)"
  - "Phase 5 (packaging : bundle installer/ + cache dans le plugin)"
tech-stack:
  added: []
  patterns:
    - "Catalogue data-driven (jq sur module.json, zéro nom en dur)"
    - "Skill thin orchestrateur (discipline writing-skills : description=triggers, corps=délégation)"
    - "VF_SCOPE explicite partout (ID4)"
key-files:
  created:
    - installer/scripts/build-module-catalog.sh
    - installer/scripts/tests/test-build-module-catalog.sh
    - installer/SKILL.md
  modified: []
decisions:
  - "Séparateur catalogue = TABULATION (name<TAB>description), stable pour cut -f2 et diff déterministe"
  - "Description du skill = triggers SEULEMENT (writing-skills CSO) — pas de résumé de workflow"
  - "Skill délègue aux 4 briques, ne réimplémente aucune logique (catalogue, deps, engine, bootstrap)"
metrics:
  duration: "~1 min"
  completed: 2026-06-04
---

# Phase 04 Plan 01 : Cœur UX d'install (catalogue + skill /vibeflow-install) Summary

Catalogue `build-module-catalog.sh` (agrège les 8 `module.json` en `name<TAB>description` via `jq`, zéro nom en dur) + skill `/vibeflow-install` orchestrateur thin (discipline writing-skills) qui enchaîne toggle scope → toggle modules → résolution+récap des deps → install scopée, en déléguant à `resolve-deps.sh`, `vibeflow-update.sh --scope` et `ensure-deps.sh` (VF_SCOPE explicite partout, ID4).

## Tasks exécutées

| Task | Nom | Commit | Fichiers |
|------|-----|--------|----------|
| 1 | build-module-catalog.sh + test isolé | 881e796 | installer/scripts/build-module-catalog.sh, installer/scripts/tests/test-build-module-catalog.sh |
| 2 | Skill /vibeflow-install (toggles, writing-skills) | ed09cde | installer/SKILL.md |

## Vérification

- **Task 1** — `bash installer/scripts/tests/test-build-module-catalog.sh` → exit 0 (6 OK / 0 KO) :
  fixture mktemp (tri alpha<zeta, dossier sans module.json exclu, descriptions non vides, 2 modules)
  + cas repo réel (exactement 8 modules, `validator` présent avec description).
  Sortie directe vérifiée : 8 lignes triées `name<TAB>description`, aucune description vide.
- **Task 2** — grep de vérif imprime `OK-ALL-REFS` : frontmatter `name: vibeflow-install` +
  `description:`, et le corps référence `resolve-deps`, `vibeflow-update.sh --scope`,
  `VF_SCOPE ... ensure-deps`, `build-module-catalog`, et cite `ID4`. 555 mots.

## Success criteria

- INST-01 : toggle scope single-select (user/project/local) décrit, single-select explicite (ID4).
- INST-02 : toggle modules peuplé depuis le catalogue (nom + description des module.json).
- INST-03 : fermeture transitive récapitulée AVANT install (via resolve-deps.sh).
- INST-04 : install déléguée à `vibeflow-update.sh --scope` + `ensure-deps.sh` via `VF_SCOPE`, scope unique partout.
- Catalogue liste les 8 modules ; son test isolé passe (exit 0).

## Discipline writing-skills appliquée

- `description` = **triggers uniquement** (premier lancement, « installe VibeFlow », « ajoute un
  module », « change de scope »…), **sans résumé de workflow** — conforme à la section CSO de
  writing-skills (« Description = When to Use, NOT What the Skill Does »).
- `name` en lettres/chiffres/tirets (`vibeflow-install`).
- Corps = **thin orchestrateur** : prose qui DÉLÈGUE aux briques livrées, ne réimplémente rien
  (pas de TUI bash, pas de copie, pas de gitignore maison). Cross-références par nom de brique
  (pas de `@`-links qui force-loadent du contexte).
- Style FR calqué sur `vf-init` / `vf-dev` (reframe vocabulaire VibeFlow, ne nomme jamais
  GSD/Superpowers à l'utilisateur).

## Deviations from Plan

None - plan exécuté exactement comme écrit.

## Isolation des tests (zsh)

Test invoqué via `/bin/bash -c` et utilisant `command grep` partout (jamais d'alias zsh hérité).
Fixtures via `mktemp -d` + `VF_MODULES_ROOT` — aucun test ne dépend du vrai `~/.claude` ni du cwd réel.

## Notes pour la suite

- Le skill suppose `VIBEFLOW_CACHE` / `VF_MODULES_ROOT` pointant sur le **cache du plugin** :
  c'est Phase 5 (packaging) qui bundlera `installer/` + le cache des modules.
- Le hook SessionStart de 1er lancement (04-02) invoquera ce skill automatiquement.

## Self-Check: PASSED

Tous les fichiers créés existent ; les 2 commits (881e796, ed09cde) sont présents dans l'historique.
