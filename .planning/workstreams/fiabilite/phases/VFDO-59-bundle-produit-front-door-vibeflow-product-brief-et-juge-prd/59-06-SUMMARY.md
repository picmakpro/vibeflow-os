---
phase: 59-bundle-produit-front-door-vibeflow-product-brief-et-juge-prd
plan: 06
subsystem: product-team-bundle
tags: [suite-de-composition, mutation, baselines, readme-compteurs]
requires: [59-01, 59-02, 59-03, 59-04, 59-05]
provides: [plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh, 5 lignes de baseline, README 18 modules / 113 suites]
key-files:
  created: [plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh]
  modified: [.planning/instruction-budget-baselines.tsv, README.md, README.fr.md]
requirements-completed: [PRDT-01, PRDT-02, PRDT-04, PRDT-06, PRDT-08, PRDT-09, PRDT-10, PRDT-11]
status: complete
commits: 4
plan_head_before: 26ed5273c574842a53815249e2442e35ce3510b3
plan_head_after: 39321ff3784eae40ad393227112e008e07af768f
actuals: {tokens: 7300, tasks: 4, commits: 4}
---

# Phase 59 Plan 06: suite du bundle, registre d'instructions, compteurs README Summary
Suite `test-product-team-bundle.sh` (448 lignes, 15 cas directs, 42 mutants, 57 OK / 0 KO / 0 SKIP, 6 s), cinq lignes de baseline lues, README à 18 modules et 113 suites.

- Cas : PTB-COMPO, MODULE, LIGNES, AGENTS, FRONT, JUGE, MANAGER, BLOC, SKILL, NOMS, GABARITS (REQ et BRIEF), GSD, CATALOG (+ témoin positif `proposable:true`). Chaque contrôle prend une racine de module, imprime `KO-<CAS>:<id>`, est rejoué sur une copie mutée : témoin positif d'abord, copie différente (`diff -rq`, sinon NON OPPOSABLE), motif de rouge exigé.
- Mutants (42), assertion / attendu / obtenu (obtenu = rouge avec le motif attendu, aucun survivant) : AGENTS manager sans SendMessage / `invariant I6` ; analyste sans vf-internal / `invariant I1 — description: porte` ; PM sans « Worker interne » / `invariant I1 — … sans le marqueur` ; prd-gate sans omitClaudeMd / `invariant I5` ; allowlist sans prd-gate / `invariant I2` ; AGENT.md + `tools: Read` / `KO-FRONT:avertissement tools absent` ; AGENT.md + champ inconnu / `avertissements=4`. prd-gate (T-59-13) : somme 99 / `KO-JUGE:somme=99` ; ablation de chaque ancre (`79`, `seuil`, `contrat-requirements`, `contrat-brief`, `human_needed`, `eliminatoire`, `bash-borne`, `detail-brief|exigences|criteres|priorites|tracabilite`) / `KO-JUGE:<id>`. Manager : ablation de `verrou`, `digest`, `human_needed`, `seuil`, `next_step_propose`, `jamais-lance`, `override` / `KO-MANAGER:<id>`. Autres : COMPO-MEMORY, MODULE (proposable, roles, requires), LIGNES-251, BLOC-ANALYSTE, SKILL-JAMAIS-TASK, NOMS (agile, marque), GABARITS ×4, GSD-ID-ILLISIBLE, CATALOG-PROPOSABLE-TRUE, tous rouges au motif attendu.
- Registre (valeurs lues dans `check-instruction-budget.sh`) : `AGENT.md` 164/36, `agents/prd-gate.md` 123/17, `vf-product-analyst.md` 65/13, `vf-product-manager.md` 152/24, `vf-product-pm.md` 78/21 ; 5 ajouts, 0 retrait, verdict `OK` ×5.
- Gates rejoués (rc) : suite 0 ; `check-version-sync.sh` 0 ; `check-instruction-budget.sh` 0 (sans SANS-BASELINE ; `BOOTSTRAP 2610 > 2000` préexistant, intact) ; `check-baseline-arbitrage.sh` 0 (CONFORME) ; `test-build-module-catalog.sh` 0 (14 OK, fichier non modifié) ; `check-gate-touche.sh` 3 (RIEN-A-JUGER). Suite aussi vérte sous `/bin/bash` 3.2 ; sans moteur GSD (`HOME` vidé) : SKIP nommé `PTB-GSD moteur GSD absent`.
- Comptes avant / après : modules 17 / 18 (badge, phrase, `ls plugin/*/module.json`) ; suites 111 / 113 (`find plugin scripts -path '*/tests/test-*.sh'`) ; 3 lignes changées par README, `VERSION` et manifestes intacts.
- Commits : 54fa71e4 (suite tracer + baselines), a1010cb3 (frontmatters, clauses), 2e5fbcdf (gabarits, GSD, catalogue), 39321ff3 (README).

## Deviations from Plan

1. [Rule 1 - précision] PTB-MODULE exige la triade `version` = `VERSION` au format `vX.Y.Z`, pas la valeur littérale `v1.0.0` : un bump normal ne doit pas rougir la suite.
2. Mutant FRONT : `tools: Read` ne change pas le compte (`tools absent` est remplacé par un avertissement `disallowedTools`) ; il rougit sur l'avertissement manquant. Un second mutant (champ inconnu) fait changer le compte à 4.
3. Mutant GSD : `**PRD-01** :` (espace avant `:`) est toléré par le moteur, donc survivant ; remplacé par `**PRD01**:`, rejeté.
4. JUGE et MANAGER : balayage d'ablation par ancre (plus large que les 2-3 mutants du plan).

Known Stubs : aucun.

## Self-Check: PASSED
Suite, 4 commits ancêtres de HEAD, registre, README présents.
