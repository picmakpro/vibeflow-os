---
name: profondeur-3-sans-outil-agent
description: "À la profondeur 3, aucun agent n'a Agent ni Task (limite runtime mesurée, pas l'allowlist, jamais appliquée à l'appel) ; Phase 40.1 = vf-coder poussé en profondeur 3 ; B1/B2"
metadata:
  type: project
---

À la profondeur 3, un agent n'a ni `Agent` ni `Task` — c'est une limite du runtime, pas son allowlist. Sonde en session principale, 2026-09-17 : aux profondeurs 1 et 2, `Agent` est visible et un lancement est accepté ; à la profondeur 3, `Agent` et `Task` sont absents quel que soit le type d'agent (`ToolSearch` `select:Agent,Task` → « No matching deferred tools found. »). L'allowlist `Agent(...)` du frontmatter n'est pas appliquée à l'exécution : `vf-coder` a lancé `gsd-executor` et `gsd-planner`, absents de sa liste. Limite observée, non documentée par Anthropic : elle peut changer avec une version de Claude Code.

Incident Phase 40.1 (2026-09-16, ~160k jetons perdus) : head dispatché en `Task` (1) → `vf-dev-manager` (2) → `vf-coder` (3). Sans outil de lancement à cette profondeur, `gsd-plan-phase` s'est arrêté net à l'étape « Spawn gsd-planner » et a rendu `blocked` sans rien écrire. Second incident, 2026-09-17 : un `vf-coder` à la profondeur 1 n'a pas tenté `gsd-quick --validate`, croyant à tort que son allowlist l'en empêchait.

**Why:** la profondeur de lancement est bornée par le runtime (outil absent à la profondeur 3), jamais par les allowlists ; et le skill interdit d'absorber le rôle du planificateur en ligne.

**How to apply:** arbitrages Samuel B1/B2 (AskUserQuestion session principale, 2026-09-17). B1 : le head est incarné en session principale via `/vf-dev`, jamais dispatché en `Task` — manager 1, `vf-coder` 2, briques GSD 3. B2 : `vf-coder` vérifie la présence de l'outil `Agent` avant toute action ; absent, il rend `blocked` + `cause: "profondeur"` + mandat intact. Sur ce retour, suivre `vf-dev-manager.md` §Contrôle de flux : remonter pour relance au bon niveau, ni coder ni dispatcher les briques en direct. Le contournement de la Phase 40.1 (un `general-purpose` qui suit la définition du planificateur, puis un `gsd-plan-checker` frais, dispatchés en direct) est antérieur à B1/B2 et contourne la voie unique : ne pas le reproduire. Voir aussi [[dispatches-via-skills-non-forkees]]. Un checker peut citer un fait de tag faux (« v2.63.0 contient a7f414a ») : exiger la commande exacte, et la rejouer avant de relayer ([[descripteur-gsd-core-non-probant]]).
