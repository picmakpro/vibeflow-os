---
phase: 59-bundle-produit-front-door-vibeflow-product-brief-et-juge-prd
plan: 07
subsystem: manuel
tags: [manuel, fr-en, product-team-bundle, comptes-recomptes]
requires: [59-04, 59-05]
provides: [manuel FR/EN à jour pour le bundle produit]
key-files:
  modified: [manual/fr/06-reference/agents.md, manual/en/06-reference/agents.md, manual/fr/06-reference/skills.md, manual/en/06-reference/skills.md, manual/fr/06-reference/couts-et-modeles.md, manual/en/06-reference/cost-and-models.md, manual/fr/03-modules/catalogue.md, manual/en/03-modules/catalog.md, manual/fr/03-modules/bundles-metier.md, manual/en/03-modules/business-bundles.md, manual/fr/05-equipe-agents/equipes-specialisees.md, manual/en/05-agent-team/specialized-teams.md, manual/fr/05-equipe-agents/les-agents-livres.md, manual/en/05-agent-team/the-agents-that-ship.md]
requirements-completed: [PRDT-11]
status: complete
commits: 4
plan_head_before: 9a3f2a6374bd1c60d793d36d369de5ce81162fc0
plan_head_after: ece01adcb4ecdee92737ff15ddd6fd44c90b707e
actuals: {tokens: 9000, tasks: 4, commits: 4}
---

# Phase 59 Plan 07: manuel FR et EN du bundle produit Summary

Quatorze pages du manuel (FR et EN, mêmes faits) nomment l'équipe produit, son skill et son exposition réelle ; comptes recomptés par commande, aucun H2 ni entrée de `toc.yml` ajouté.

- Comptes (commande, valeur) : agents à un niveau `find plugin -path '*/agents/*.md' | awk -F/ 'NF==4'` = 29, plus `find plugin -maxdepth 2 -name AGENT.md` = 7, soit 36 (31 avant) ; `model:` lu dans les 36 frontmatters = 12 opus, 24 sonnet (10 / 21 avant), égal au comptage de la colonne Modèle des deux tables ; skills `find plugin -iname SKILL.md | awk '!/reference\/content/'` = 23 (22 avant). Managers : 7 (six « autres » que `vf-test-orchestrator`), faces : 7. Aucun écart avec les 36 / 12 / 24 / 23 attendus.
- Exposition dite : `product-team-bundle` absent du catalogue et des presets (`proposable:false`), posé par `install --all` ou quand on le nomme, visible aux postes product et solo, un poste est une vue ; noté à côté des trois bundles métier sans les recompter (« Trois bundles sont livrés » intact).
- Contrôles : `bash manual/.tools/check-manual.sh` rc 0 (C0 à C6 verts, 5 avertissements 100-200 lignes préexistants, aucune page touchée concernée) ; `scripts/check-machine-paths.sh` rc 0 ; `scripts/check-affirmation-non-mesuree.sh` (G-4, couvre `manual/**`) rc 0 ; `scripts/check-version-sync.sh` rc 0 ; `manual/toc.yml` inchangé (`git diff --quiet` merge-base origin/main, rc 0). `ci.yml` ne porte pas d'autre contrôle du manuel que `check-manual.sh` et G-4.
- Verifs du plan : tâche 1 lignes=36 titre=36 sur les deux langues ; tâche 2 sections `### product-team-bundle` présentes, 0 occurrence de l'ancien compte ; tâche 3 faits `proposable` et `install --all` présents ; tâche 4 `prd-gate`, `vibeflow-product`, `vf-product-manager` présents.
- Commits : e2d5ab77 (agents), dc4efacf (skills, coûts), c58ed31b (catalogue, bundles), ece01adc (équipes, agents livrés).

## Deviations from Plan

1. [Rule 1 - périmé] `equipes-specialisees` : « aux quatre équipes de cette page » devenait faux avec l'équipe produit ; remplacé par « aux équipes de cette page » (FR et EN). Date de revérification de la page skills passée de 2026-10-02 à 2026-10-27 (recomptée ce jour).
2. Paragraphe produit des équipes spécialisées placé sans H3, avant « Une équipe n'est jamais présentée… » (le plan laissait le choix).

## Deferred Issues (hors périmètre, non corrigées)

`manual/fr/02-concepts/agents-skills-commandes.md` (l.14, l.69) et `manual/en/02-concepts/agents-skills-and-commands.md` (l.14, l.67) disent « vingt-deux / twenty-two agents » : compte déjà périmé avant ce plan (31 agents), page absente de `files_modified`. À traiter dans un plan dédié.

## Self-Check: PASSED
14 pages modifiées, 4 commits ancêtres de HEAD, aucun stub.
