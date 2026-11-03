---
name: e2e-c5-plafond-250-lignes
description: test-roles-e2e.sh E2E-C5 rougit dès qu'un agent dépasse 250 lignes — plus strict que ADR-029 (alerte 251, plafond 300) ; une seule ligne de frontmatter suffit
metadata:
  type: project
---
`plugin/_internal/tests/test-roles-e2e.sh` (cas E2E-C5) exige que **aucun** fichier d'agent ne dépasse 250 lignes. C'est un rouge, pas l'avertissement non bloquant d'ADR-029. `check-agents.sh` et `check-instruction-budget.sh` restent verts à 251, et aucun gate du job `gates` ne le voit.

**Why:** lot A, 2026-10-29 : ajouter `vf-optional-agents:` au frontmatter de vf-dev-manager.md (250 → 251) est passé la revue, les gates et les suites ciblées. Seul le rejeu de la découverte complète du job `tests` l'a attrapé, après l'ouverture de la PR #168. Correctif : retirer une ligne vide (4d778590).

**How to apply:** tout mandat qui ajoute des lignes à un agent proche de 250 prévoit le retrait compensatoire dès le départ, et nomme `test-roles-e2e.sh` dans les suites à rejouer. Voir [[non-regression-complete-est-un-geste-de-manager]].
