---
name: vf-coder-ne-peut-pas-planifier
description: vf-coder dispatché par un manager n'a aucun outil de spawn — gsd-plan-phase bloque à « Spawn gsd-planner » ; dispatcher le planificateur en direct
metadata:
  type: project
---

Un `vf-coder` dispatché par `vf-dev-manager` n'a ni `Agent` ni `Task` à sa profondeur, malgré son allowlist. `gsd-plan-phase` s'arrête donc net à l'étape « Spawn gsd-planner » : il rend `blocked` sans rien écrire (Phase 40.1, 2026-09-16, ~160k jetons perdus). `gsd-planner` n'est d'ailleurs pas dans l'allowlist du manager non plus.

**Why:** les sous-agents imbriqués ne peuvent pas lancer de sous-agent, et le skill interdit d'absorber le rôle du planificateur en ligne.

**How to apply:** pour un mandat de planification, dispatcher en direct un `general-purpose` qui lit et suit intégralement `~/.claude/agents/gsd-planner.md`, puis un `gsd-plan-checker` frais, lui aussi en direct, à chaque tour. Les révisions passent par SendMessage au même planificateur, qui garde son contexte. Voir aussi [[dispatches-via-skills-non-forkees]]. Un checker peut citer un fait de tag faux (« v2.63.0 contient a7f414a ») : exiger la commande exacte, et la rejouer avant de relayer ([[descripteur-gsd-core-non-probant]]).
