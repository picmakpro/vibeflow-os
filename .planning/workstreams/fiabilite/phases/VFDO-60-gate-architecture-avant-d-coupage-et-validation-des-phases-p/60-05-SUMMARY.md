---
phase: 60-gate-architecture-avant-d-coupage-et-validation-des-phases-p
plan: 05
subsystem: product-team-bundle
tags: [architecte, worker-interne, monde-ferme, baseline, qual-01, mutants]
requires: [60-02, 60-04]
provides: [vf-product-architect, livrable-architecture]
affects: [60-06, 60-08, 60-09]
key-files:
  created: [plugin/product-team-bundle/agents/vf-product-architect.md]
  modified: [plugin/product-team-bundle/agents/vf-product-manager.md, plugin/product-team-bundle/AGENT.md, plugin/product-team-bundle/skills/vf-product/SKILL.md, plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh, .planning/instruction-budget-baselines.tsv, plugin/product-team-bundle/module.json, plugin/product-team-bundle/VERSION, plugin/product-team-bundle/README.md, plugin/product-team-bundle/CHANGELOG.md]
status: complete
commits: 3
plan_head_before: a532511400cc96b35c0cd3fbd2d5ac778b745538
plan_head_after: e38983c46c1b562bff99308f8c745adb78685568
actuals: {tokens: 8100, tasks: 3, commits: 3}
---

# Phase 60 Plan 05: worker architecte du bundle produit Summary

Worker interne `vf-product-architect` (sonnet, sans Bash ni Agent, skill `software-architecture` câblé) dispatché par le manager en monde fermé, livrable `architecture` à INSTR constante, route de la front door, ligne de baseline neuve, bundle v1.0.0 -> v1.1.0.

## Registre et budget (check-instruction-budget.sh rc 0 avant et après chaque commit)
- Ligne neuve posée : `vf-product-architect.md` 81 lignes, 17 instructions (valeurs lues dans la sortie du gate, verdict OK). Diff du registre : 1 ajout, 0 retrait ; `check-baseline-arbitrage.sh` rc 0.
- INSTR avant -> après : AGENT.md 36 -> 36, prd-gate 17 -> 17, analyste 13 -> 13, manager 24 -> 24, PM 21 -> 21 (manager 152 -> 161 lignes, front door 164 -> 166). Skill vf-product 24 -> 25 lignes (plafond 500).

## Les trois formes CI de check-agents (--strict --manifest-freshness=strict)
- `--agents-dir=plugin/product-team-bundle/agents` rc 0 (4 avertissements « aucun skill cable » sur les autres agents) ; `--file AGENT.md` rc 0 (3 avertissements) ; monde fermé `--resolve-agents=strict` sur chaque `plugin/*/agents` rc 0. Avec `--skills-dir=plugin`, `software-architecture` se résout, sans avertissement de préchargement (93 lignes).

## Suite test-product-team-bundle.sh (104 OK / 0 KO / 0 SKIP, rc 0)
- Neufs : `AGENTS` et `CORPUS` étendus ; `PTB-ARCHI` + 11 ablations d'ancres (`PTB-MUT-ARCHI-*`), `ARCHI-TOOLS-BASH`, `ARCHI-TOOLS-AGENT`, `ARCHI-AUTO-VALIDATION` ; `PTB-MUT-AGENTS-I2-ARCHI` (jeton `invariant I2`) et `-I1-ARCHI` ; six ancres manager de plus (`PTB-MUT-MANAGER-*`) ; `PTB-FRONT-ARCHI` + 5 ablations (route, signal, Iron Law 4, références, skill).

## Version
product-team-bundle v1.0.0 -> v1.1.0 (VERSION, module.json, README identiques) ; `proposable:false`, `roles:["product"]`, `requires` inchangés ; `check-version-sync.sh` rc 1, seules lignes rouges « 113 suites » != 116 (attendu jusqu'à 60-07, P60-PL-17), aucune ligne du bundle.

## Autres contrôles
`check-skills.sh --strict --file` du skill rc 0 ; `check-gate-touche.sh` rc 0 (aucun chemin de surface touché, pas de trailer) ; `check-machine-paths.sh` et `check-ajout-retrait.sh --strict` rc 0 ; frontmatter de la front door et description du skill identiques à la base de phase.

## Deviations from Plan
- Iron Law 4 de la front door : « seul fichier **nouveau** que j'écris moi-même » (et non « seul fichier que j'écris moi-même », faux puisque la front door écrit aussi le PRD en geste simple).
- Le test d'auto-validation (`ARCHI-AUTO-VALIDATION`) et les deux mutants d'outils (Bash, Agent) s'ajoutent au plan pour T-60-18 et T-60-22.

## Points ouverts
- Hypothèses A4/A5/A6 (architecte sans mappeur, sonnet, GSD pouvant manquer au poste product) et P60-H-02 portées telles quelles, à confirmer par Samuel.
- Commits : 16b8bdae (agent, allowlist, baseline, suite), 0d1de756 (manager, front door, skill, ancres), e38983c4 (minor).

## Self-Check: PASSED
