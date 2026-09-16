---
title: Révision de doctrine — agentique first, ouvert à la collaboration humaine
date: 2026-09-16
context: session /gsd-explore « équipe produit VibeFlow », arbitrages Samuel (AskUserQuestion, session principale, 2026-09-16)
status: décision de principe, ADR à rédiger au cadrage du milestone equipe-produit-v1.0
---

# Révision de doctrine — agentique first, ouvert à la collaboration humaine

## La décision

La bascule agentique de v2.33.0 (spec `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`,
mémoire « ne jamais recréer de couche de synonymes ») reste la doctrine par défaut : l'intelligence vit
dans les agents, GSD est l'interface directe, aucun verbe-façade.

Elle est **amendée** sur deux points, arbitrage Samuel (AskUserQuestion, session principale, 2026-09-16) :

1. **Un rôle humain peut changer le comportement d'une front door.** Un rôle de poste (solo, product,
   dev) touche le catalogue installé, le contexte injecté en début de session ET le routage des front
   doors (« vibeflow-head conscient du rôle » : il redirige vers `vibeflow-product` au lieu de dispatcher
   `vf-coder` quand le poste est product). Ce n'est pas une couche de synonymes : aucun verbe nouveau,
   le même agent lit un contexte de plus. Formulation retenue : **agentique first, ouvert à la
   collaboration humaine**.
2. **Le vocabulaire des rôles s'aligne sur BMAD par renommage, jamais par alias.** Un renommage
   remplace un nom (l'ancien disparaît, test anti-alias, migration one-way des labs via
   `/vf-calibrate`). Un alias en ajoute un et recrée la façade enterrée en v2.33.0. Exception nommée par
   Samuel : **« manager » reste « manager »** — « scrum master » évoque la cohésion d'équipe, pas
   l'exécution réelle du kanban et de la feuille de route qu'un `vf-dev-manager` pilote.

## Ce que ça touche

- ADR à amender ou à créer : la décision v2.33.0 n'a pas d'ADR numéroté dans `docs/ADR.md` (vérifié le
  2026-09-16, aucune entrée « bascule agentique » ni « synonymes ») ; le cadrage devra soit en écrire un
  rétroactif, soit ancrer l'amendement dans la spec du 2026-07-25.
- ADR-053 (un manager, un verrou de driver) : inchangé par cette note ; l'amendement « un manager par
  compartiment » reste porté par la phase D-02 de partition réelle d'un lab (spec head §6).
- Précédent immédiat : la Phase 40 a renommé `vibeflow-dev` → `vibeflow-head` avec test anti-alias.
  C'est le moule de tout renommage BMAD à venir (coût réel : engine, manifestes, tests, mémoire
  per-projet, labs installés).

## Ce que ça ne change pas

- « Un rôle est une vue, pas un droit » : git ne cloisonne rien, aucune promesse de contrôle d'accès.
- Le rôle change ce que l'humain voit et ce que la front door propose, jamais ce que les workers
  lisent : `PROJECT`, `REQUIREMENTS`, `ROADMAP`, `STATE`, registres, digest de mission identiques.
- ADR-031 : toute validation reste humaine ; les gates de rôle sont des scripts advisory + refus des
  managers, pas des hooks bloquants.

Voir la graine `.planning/seeds/SEED-001-equipe-produit-v1.md` et la spec
`docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md` § Arbitrages.
