---
created: 2026-11-01
source: /gsd-explore cockpit (note 2026-11-01-cockpit-facettes)
priority: haute — préalable au cadrage de la phase cockpit
---

# Commiter le dossier du spike 002

`.planning/spikes/002-cockpit-code-projet/` n'est pas suivi par git sur `docs/etude-floorplan`,
alors que les spikes 003 à 006 (commités) en dépendent : copie figée de floorplan v0.6.0 avec ses
patchs P1-P8 (`VENDORED.txt`), extensions `00-vibeflow.js`, `70-vf-live.js`, `80-vf-fr.js`,
générateurs `vf-code-arch.mjs` et `vf-project-graph.mjs`, `build-cockpit.mjs`, captures.
≈ 3,6 Mo, dont ELK 1,5 Mo. L'étude `docs/research/2026-11-01-etude-floorplan-cockpit.md` est dans
le même cas. Décider : commit tel quel, ou sans la copie figée (re-vendorisable depuis
`VENDORED.txt`). Si le worktree disparaît avant, 003 à 006 ne tournent plus.
