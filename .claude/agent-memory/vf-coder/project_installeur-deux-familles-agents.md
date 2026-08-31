---
name: installeur-deux-familles-agents
description: L'installeur pose DEUX familles d'agents (AGENT.md racine + agents/*.md) et met tous les scripts à plat — la population réelle n'est pas celle de plugin/*/agents
metadata:
  type: project
---

`vibeflow-update.sh` pose dans `.claude/agents/` **deux** familles, pas une :

- **Type 3** — `plugin/<mod>/AGENT.md` → `.claude/agents/<mod>.md` (modules mono-agent)
- **Type 3b** — `plugin/<mod>/agents/<nom>.md` → `.claude/agents/<nom>.md`

Mesure 2026-08-04 : **31 fichiers** au total, dont **6 `AGENT.md`**. Un balayage sur
`plugin/*/agents` n'en voit que 25.

Et `copy_module_scripts` copie **`scripts/*.sh` à plat** dans `.claude/scripts/`, tous modules
confondus (seul `tests/` garde un sous-dossier). Chez l'utilisateur, les scripts de conductor,
dev-orchestrator et planning-core sont donc **voisins** ; dans l'arbre du dépôt, non. Tout
`source`/référence croisée doit résoudre les deux dispositions.

**Why:** un durcissement de `check-agents.sh` (exigence `effort:`) propagé aux seuls 25 a laissé 5
modules non conformes ; le Gate C du job `lab-frais`, qui balaye la population **installée**, les a
découverts trop tard et sous `set -eu`. Le gate par module ne voyait pas ce qu'il prétendait garder.

**How to apply:** toute règle appliquée « à tous les agents » se vérifie sur
`plugin/*/AGENT.md` **et** `plugin/*/agents/*.md` — dériver la liste en glob shell, jamais avec
`find -path` (rtk avale le flag) ni `grep` (tronque). Voir [[placement-lib-partagee-planning-core]]
pour la contrainte de dépendances qui va avec la disposition à plat.
