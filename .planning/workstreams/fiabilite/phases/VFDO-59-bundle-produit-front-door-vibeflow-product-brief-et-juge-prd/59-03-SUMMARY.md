---
phase: 59-bundle-produit-front-door-vibeflow-product-brief-et-juge-prd
plan: 03
subsystem: dev-orchestrator
tags: [head, redirection-poste, product-routing, t44, instruction-budget]
requires: []
provides: [plugin/dev-orchestrator/references/product-routing.md]
key-files:
  created: [plugin/dev-orchestrator/references/product-routing.md]
  modified: [plugin/dev-orchestrator/AGENT.md, plugin/dev-orchestrator/references/_index.md, plugin/dev-orchestrator/references/intent-routing.md, plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh, plugin/dev-orchestrator/VERSION, plugin/dev-orchestrator/module.json, plugin/dev-orchestrator/README.md, plugin/dev-orchestrator/CHANGELOG.md]
requirements-completed: [PRDT-07, PRDT-12]
status: complete
commits: 3
plan_head_before: d597252e301f0797f2df89f8557d74512d0f135d
plan_head_after: d6f1cde11a0529733c28f949bc4b6bb3aacb6eab
actuals: {tokens: 9000, tasks: 3, commits: 3}
---

# Phase 59 Plan 03: redirection du poste product par le head Summary

Le head lit le poste par `vf-role.sh get` et oriente vers `/vf-product` au poste product, à zéro instruction ajoutée dans `AGENT.md` (33 avant, 33 après) ; dev-orchestrator passe de v2.28.4 à v2.29.0.

- Lignes ajoutées à `AGENT.md` (3) : pointeur `> **Poste product** — la ligne « Poste : X » du démarrage de session, confirmée par `vf-role.sh get`, décide de la porte : au poste `product`, ou devant une intention produit (brief, PRD, critères d'acceptation), lire d'abord `.claude/agents/dev-orchestrator-references/product-routing.md`, qui prime sur la proposition d'init ci-dessous.` (sous le titre du garde-fou, avant FIRST-02) ; ligne de carte `| brief produit / PRD / exigences / critères d'acceptation | skill `vf-product` (module product-team-bundle) → agent `vibeflow-product` |` ; ligne de Références `- Redirection par poste et porte produit : `.claude/agents/dev-orchestrator-references/product-routing.md``. Frontmatter intact (`cmp` sur les 7 premières lignes, rc 0).
- `product-routing.md` (4 sections, 57 lignes) : lecture du poste, poste product, postes solo et dev, ce que la page ne fait pas.
- Budget d'instructions de `plugin/dev-orchestrator/AGENT.md` : baseline 209 lignes / 33 instructions ; mesuré avant 212 / 33 (HEAD), après 216 / 33, verdict `OK+LIGNES-EN-HAUSSE`, `check-instruction-budget.sh` rc 0. Repli de P59-PL-10 non utilisé, `.planning/instruction-budget-baselines.tsv` non touché, aucun trailer G-1 ni `Gate-Touche` requis (la suite du module dev-orchestrator est hors des six classes de G-2 ; aucun ajout surveillé par `Ajout-Retrait`).
- T44 : 13 lignes vertes, 5 contrôles (a pointeur avant FIRST-02, b contenu, c carte, d index et Références, e carte exhaustive) et 7 mutants DISCRIMINANT (pointeur, ordre, lecture, carte, index, Références, carte exhaustive). Suite complète : 292 OK / 0 KO, rc 0, environ 41 s.
- Vérifications : `check-capability-activation.sh` rc 0 ; `check-baseline-arbitrage.sh` rc 0 (CONFORME) ; `check-ajout-retrait.sh --strict` rc 0 ; `check-machine-paths.sh` rc 0 ; `check-version-sync.sh` aucune ligne rouge nommant dev-orchestrator (restent rouges : comptes de suites 111 contre 112, attendu jusqu'à 59-06).
- Commits : 03897933 (tâche 1, tracer), 3b80e4eb (tâche 2), d6f1cde1 (tâche 3).

## Deviations from Plan

Aucune sur le fond. Le cas T44 a été écrit en même temps que la référence et le pointeur (pas de rouge intermédiaire commité séparément) ; la discrimination est prouvée par les mutants, tous refusés avec témoin positif.

## Self-Check: PASSED
