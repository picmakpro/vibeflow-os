---
phase: 59-bundle-produit-front-door-vibeflow-product-brief-et-juge-prd
plan: 05
subsystem: product-team-bundle
tags: [front-door, skill, gabarit-brief, readme, poste-en-avis]
requires: [59-02, 59-04]
provides: [plugin/product-team-bundle/AGENT.md, plugin/product-team-bundle/skills/vf-product/SKILL.md, plugin/product-team-bundle/references/BRIEF.template.md, plugin/product-team-bundle/README.md]
key-files:
  created: [plugin/product-team-bundle/AGENT.md, plugin/product-team-bundle/skills/vf-product/SKILL.md, plugin/product-team-bundle/references/BRIEF.template.md, plugin/product-team-bundle/README.md]
  modified: []
requirements-completed: [PRDT-01, PRDT-03, PRDT-08, PRDT-09, PRDT-11]
status: complete
commits: 5
plan_head_before: d935fbea2719a68d9dd7444b3d49c3fb18ca232c
plan_head_after: bbbf3b8bb5a94dfa78e6c5af0c6d692259bfc882
actuals: {tokens: 5100, tasks: 4, commits: 5}
---

# Phase 59 Plan 05: front door `vibeflow-product`, skill `/vf-product`, gabarit BRIEF, README Summary

Front door sans `tools:` ni allowlist, incarnée par `/vf-product` (jamais en Task) : le poste lu par `vf-role.sh get` est un avis, un geste simple se produit en session puis passe par `check-prd.sh`, une mission PROPOSE `Task(vf-product-manager)` et attend le feu vert.

- Lignes : AGENT.md 164 (plafond 250), SKILL.md 24 (plafond 80), BRIEF.template.md 31 (plafond 40), README.md 132 (plafond 160 ; résumé EN 14 lignes non vides).
- `check-agents --file` sur AGENT.md (arguments de `ci.yml`) : rc 0, exactement 3 avertissements (nom différent du fichier, aucun skill câblé, tools absent). Les trois étapes `ci.yml` rejouées : dossiers `found=7 fail=0`, `AGENT.md` `found=7 fail=0`, monde fermé `found=7 fail=0`.
- `check-skills --strict` : fichier rc 0 sans avertissement ; arbre `--skills-dir=plugin --callers-root=plugin` rc 0, 0 ligne `⚠` nommant `vf-product`.
- `check-ajout-retrait --root . --strict` rc 0 : `AJOUT-COUVERT: plugin/product-team-bundle/skills/vf-product/SKILL.md (skill)`, trailer à trois segments dans 88aaa02e.
- Gabarit BRIEF : brut, `check-prd.sh --brief` rend 1 avec 5 lignes `ELIMINATOIRE rubrique BRIEF` ; copie remplie rend 0.
- `check-machine-paths` rc 0. Aucune suite rejouée (le plan n'en cite aucune).
- États rouges attendus, constatés : `check-instruction-budget` rc 2, `SANS-BASELINE` sur 5 chemins du bundle (AGENT.md 164 lignes / 36 instructions, et les 4 agents de 59-04) ; `check-version-sync` rc 1 sur le seul compteur README (badge et texte 17 modules contre 18, 111 suites contre 112) ; l'en-tête `**Version**` des README de modules est aligné (18 déclarés). Registre de baselines : propriété de 59-06.
- Commits : 88aaa02e (front door + skill, trailer), d45a7b41 (correctif SKILL.md), 78724608 (corps de la front door), b1ee09a7 (gabarit BRIEF), bbbf3b8b (README).

## Deviations from Plan

**1. [Rule 1 - Bug] SKILL.md : avertissements de dérive D-Q1** — la ligne « juger le PRD … verdict du juge `prd-gate` » levait deux avertissements (`vf-gate-bloquant`, `vf-couche-qualite`), contraire au critère « aucun `⚠` ne nomme `vf-product` ». Reformulée sans les mots « juge » et « gate » en prose (commit d45a7b41, un commit de plus que prévu).

## Known Stubs

Aucun.

## Self-Check: PASSED
4 fichiers présents, 5 commits ancêtres de HEAD.
