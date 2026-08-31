---
name: dispatches-via-skills-non-forkees
description: Aucune skill ne déclare context: — un agent qui invoque une skill dispatche lui-même les agents qu'elle nomme, angle mort de tout recensement d'allowlist
metadata:
  type: project
---

Sur les ~140 `SKILL.md` de `~/.claude/skills/`, **aucun** ne déclare `context:`. Aucune skill n'est
donc forkée : ses instructions se chargent dans le contexte de l'agent qui l'invoque, et c'est donc
**cet agent** qui appelle les `Agent(...)` que la skill nomme — sous SON allowlist, pas celle d'un
sous-contexte.

Conséquence concrète mesurée en Phase 15 : `vf-dev-manager` dispatche lui-même
`gsd-doc-classifier`, `gsd-doc-synthesizer`, `gsd-roadmapper` (via `gsd-ingest-docs`),
`gsd-doc-verifier`/`gsd-doc-writer` (via `gsd-docs-update`), `gsd-planner`/`gsd-plan-checker`/
`gsd-pattern-mapper` (via `gsd-plan-phase`), `gsd-integration-checker` (via `gsd-audit-milestone`) —
aucun de ces noms n'apparaît dans son prompt.

**Why:** une allowlist `Agent(...)` construite en lisant seulement le prompt de l'agent et ses
`references/` rate systématiquement cette couche. Un agent absent de l'allowlist voit son dispatch
refusé **sans erreur visible** : l'audit de milestone rend un verdict amputé, l'ingestion s'arrête
avant la synthèse, la re-validation de plan ne se fait pas. Le coût d'erreur est asymétrique et
silencieux — c'est la pire combinaison.

**How to apply:** tout recensement de dispatches se fait à trois niveaux — (1) corps de l'agent,
(2) `references/` chargées on-demand, (3) **agents nommés par chaque skill invoquée**, à vérifier
dans `~/.claude/skills/<nom>/SKILL.md`. Et la vérification doit être une **dérivation indépendante** :
en Phase 15, le 1er recensement a livré 7 noms, le 2e 14, un audit à qui on avait interdit de lire
les précédents en a trouvé 18. Un second passage qui relit le premier recopie l'angle mort au lieu
de le corriger — il faut explicitement interdire la lecture de l'inventaire amont dans le mandat.

Voir aussi [[check-agents-vacuous-green]] : rien ne linte ces allowlists, donc aucune machine ne
rattrapera une omission.
