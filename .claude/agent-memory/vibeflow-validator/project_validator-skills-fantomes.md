---
name: validator-skills-fantomes
description: 3 des 6 skills déclarés dans le frontmatter de l'agent vibeflow-validator n'existent pas — les phases densité et dette doivent être menées à la main
metadata:
  type: project
---

`plugin/validator/AGENT.md` déclare 6 skills. Au 2026-07-25, **3 ne résolvent pas** :
`agent-density-auditor` (template only, module doc-only jamais posé comme skill exécutable),
`dette-detector` (aucun `SKILL.md` nulle part), `checkpoint` (seulement un
`checkpoint-trigger-template.md`). Résolvent bien : `consolidator`, `infrastructure-audit`,
`audit-architecture`.

Corollaire : **`/checkpoint` n'existe pas** comme commande, alors qu'il est documenté comme telle
dans 8+ fichiers. `plugin/commands/` ne contient que `vf-audit`, `vf-calibrate`, `vf-new-lab`,
`vf-planning`, `vf-update`, `vibeflow`. La commande réelle est **`/vf-audit`**.

**Why:** signalé comme finding release-bloquant dans
`reports/validator/2026-07-25-validator.md` (F3). Tant que ce n'est pas corrigé, la procédure en
5 phases de l'agent décrit des délégations impossibles.

**How to apply:** ne pas perdre de temps à invoquer ces 3 skills. Mener la phase densité par mesure
directe (`wc -l` sur `plugin/*/agents/*.md` et les `SKILL.md`, plafonds 250/500) et déléguer la
phase dette à un agent générique avec une consigne explicite. **Vérifier d'abord si le correctif a
été appliqué** — c'est la recommandation n°1 du rapport, elle peut avoir été traitée depuis.

Attention aux faux positifs de densité : `contracts-template.md`, `_reference/lead-knowledge.md`,
les `*.blueprint.md` et les sous-agents vendored de `skill-creator` vivent sous `agents/` mais **ne
sont pas des agents**. Voir [[gates-vacuous-green]].
