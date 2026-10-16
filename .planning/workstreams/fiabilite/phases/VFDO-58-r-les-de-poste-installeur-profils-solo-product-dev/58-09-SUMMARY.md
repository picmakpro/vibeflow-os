---
phase: 58-r-les-de-poste-installeur-profils-solo-product-dev
plan: 09
status: complete
requirements: [RLPO-11, RLPO-10, RLPO-12]
commits: [1a0dd052 (suite e2e), 68d01a76 (outil de livraison)]
---

# 58-09 — preuves e2e des critères 1, 2, 5 et outil de livraison

Arbitrages : P58-D-01..14, arbitrage Samuel, AskUserQuestion session principale, 2026-10-16.

## Mesures
- Cardinal de D (chemins des manifestes dev de l'install de référence) : **60**, 0 chemin partagé écarté ; 6 hooks dev dérivés.
- Suite non armée : 33 s, 11 OK, 1 SKIP visible (`E2E-C2-AB`). Armée (`VF_ROLE_E2E_LIVRAISON=1`) : 66 s, 14 OK, 0 SKIP, 472 fichiers comparés. `/bin/bash` 3.2 : 14 OK armée.
- E2E-C5 : 31 fichiers d'agent (6 dossiers `agents/` + 6 `AGENT.md`), aucun au-delà de 250 lignes.
- Première divergence du comparateur sur le témoin product : `./.claude/.vibeflow-fragments/dev-orchestrator.json`.
- Écart d'exécution : l'engine « nouveau » est surchargeable par `VF_ROLE_E2E_INTERNAL` (cran de mutation, jamais posé en CI).

## Mutations (rougissent)
- M1 : `role_visible` remplacé par `true` dans `install --all` -> E2E-C1 (3 modules au registre), E2E-C1-ARTEFACTS (60 artefacts, 6 hooks) en KO.
- M2 : un octet ajouté à l'en-tête de `.worktreeinclude` de l'engine nouveau -> E2E-C2-AB en KO, première divergence `./.worktreeinclude`.

## Outil `check-livraison-58.sh`
Base de phase : `5e1b1f33d9d679e79f6a19c282aff2b258345176` (ancêtre de HEAD, enfant = `docs(58): cadrage de la Phase 58…`).
`gitignore-intact` 0 · `fichiers-intacts` 0 (47 chemins) · témoins : copie d'engine mutée 1 · liste avec `plugin/planning-core/module.json` 1 ·
`clients` sans variable 2 · fichier vide 2 · fichier dans le dépôt 2 · liste hors dépôt portant `vibeflow-role` 1 (sortie sans ce mot) ·
liste sans occurrence 0. Aucun nom de client n'existe dans le dépôt : critère 6 NON-VÉRIFIABLE jusqu'au checkpoint de 58-11.

## Gates
`check-agents --strict --manifest-freshness=strict` 6 dossiers + 6 AGENT.md verts ; `check-planning-consumers-registered` 0 ; `check-machine-paths` 0 ; `check-gate-touche` 0.
