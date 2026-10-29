---
phase: 60-gate-architecture-avant-d-coupage-et-validation-des-phases-p
plan: 08
subsystem: manual
tags: [manuel, fr-en, gate-architecture, phases-proposees, comptes-agents]
requires: [60-05, 60-06]
provides: [manuel-gate-architecture, comptes-agents-37]
key-files:
  modified: [manual/fr/02-concepts/gates-et-validation-humaine.md, manual/en/02-concepts/gates-and-human-validation.md, manual/fr/04-cycle-de-dev/planifier.md, manual/en/04-development-cycle/planning.md, manual/fr/01-demarrer/installation.md, manual/en/01-get-started/installation.md, manual/fr/06-reference/agents.md, manual/en/06-reference/agents.md, manual/fr/06-reference/couts-et-modeles.md, manual/en/06-reference/cost-and-models.md, manual/fr/05-equipe-agents/les-agents-livres.md, manual/en/05-agent-team/the-agents-that-ship.md, manual/fr/02-concepts/agents-skills-commandes.md, manual/en/02-concepts/agents-skills-and-commands.md, manual/fr/05-equipe-agents/equipes-specialisees.md, manual/en/05-agent-team/specialized-teams.md]
status: complete
commits: 3
plan_head_before: 4aaa8592bb3a7f8ad56859823aaf274e9625a5b9
plan_head_after: 7d7d8b8b8640ad0089108f38f99369818ebf49f8
actuals: {tokens: 3000, tasks: 3, commits: 3}
---

# Phase 60 Plan 08: manuel FR+EN, gate architecture et étapes proposées Summary

Seize pages du manuel (huit paires FR/EN) expliquent le refus de découper sans architecture validée, l'étape proposée et le verbe `vf-validation.sh validate`, avec les limites écrites (« Regenerate all », phase à la main, `gsd-discuss-phase` et `gsd-quick` non gardés, un poste est une vue) ; les comptes d'agents sont recomptés : 37.

## Pages touchées (commits)
- 6f7259c5 (tracer) : gates et validation humaine (`###` sous « Un script qui refuse »), planifier (`###` « Une étape proposée attend un dev »), installation (puce dans `### Ton poste`). Aucune H2 ajoutée.
- 3e85528b : `agents.md` (titre 37, ligne `vf-product-architect`, commandes bornées), `couts-et-modeles.md`.
- 7d7d8b8b : `les-agents-livres`, `agents-skills-commandes`, `equipes-specialisees` (chaîne produit avec l'architecte).

## Comptes mesurés (2026-10-29, HEAD de branche)
- `find plugin -mindepth 3 -maxdepth 3 -type f -path 'plugin/*/agents/*.md' | awk 'END{print NR}'` = 30 ; `find plugin -mindepth 2 -maxdepth 2 -type f -name AGENT.md | awk 'END{print NR}'` = 7 ; total 37.
- `model:` sur le même ensemble : 12 opus, 25 sonnet (douze / vingt-cinq en lettres). Titres FR et EN = 37. La page cite désormais les deux commandes bornées (la non bornée aurait compté 60).

## Gates (rc)
- `check-manual.sh` rc 0 après chaque tâche (C0 à C6 tous ✓, zéro `✗`) ; vérifications automatisées du plan : tracer (verbe + ARCHITECTURE.md sur 4 pages) rc 0, comptes rc 0, commandes bornées rc 0, anciens comptes (36, trente-six, thirty-six) 0 résidu dans tout `manual/`.
- `check-machine-paths.sh` rc 0 ; `check-gate-touche.sh` rc 0 (aucun chemin surveillé, aucun trailer dû) ; `manual/toc.yml` inchangé, aucun fichier neuf sous `manual/`. Aucune baseline touchée.

## Deviations from Plan
None - plan executed exactly as written. Les liens relatifs vers la page « gates » (planifier, installation) ajoutés en plus du strict nécessaire (C3 vert).

## Points ouverts
- Ton de la puce d'installation et de la sous-section planifier à relire par Samuel ; P60-H-01 et P60-H-03 (déjà portées par 60-06) restent à confirmer.

## Self-Check: PASSED
Trois commits dans l'historique de la branche, seize fichiers modifiés et commités, STATE/ROADMAP/REQUIREMENTS non touchés.
