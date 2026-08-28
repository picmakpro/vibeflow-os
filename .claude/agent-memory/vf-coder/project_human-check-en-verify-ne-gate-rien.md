---
name: human-check-en-verify-ne-gate-rien
description: Un `<human-check>` placé en `<verify>` s'exécute APRÈS l'`<action>` — une question qui doit précéder l'écriture exige sa propre tâche `type="checkpoint"` ET `autonomous: false`.
metadata:
  type: project
---

Dans un `PLAN.md` GSD, le bloc `<verify>` est évalué **après** l'`<action>` de la même tâche. Un
`<human-check>` qui dit « ne pas exécuter cette tâche avant réponse » n'y gate donc **rien** : au
moment où il est lu, le geste est fait. Une question qui doit précéder la première écriture exige
**sa propre tâche `<task type="checkpoint">`**, placée avant, sans écriture.

Et le frontmatter doit suivre : **`autonomous: false`**. Avec `autonomous: true`, le vérificateur
de structure refuse le plan (`"Has checkpoint tasks but autonomous is not false"`) et le moteur
traite le checkpoint comme auto-approuvable — le gate est simplement déplacé du `<verify>` vers le
frontmatter, sans que rien ne le signale.

**Why :** sur le replan 23-05, la question bloquante (une prémisse d'arbitrage démentie par mesure)
avait été correctement rédigée mais logée en `<verify>` ; le plan-checker l'a rendue en bloquant.
Corrigée en tâche 0, elle a immédiatement produit un second bloquant sur `autonomous:` — les deux
vont ensemble, toujours.

**How to apply :** toute question de type ADR-031 (remonter, ne pas trancher) qui conditionne
l'écriture → tâche `checkpoint` en tête + `autonomous: false`. Critère de sortie d'une telle tâche :
comparer deux `git status --porcelain` **restreints aux chemins de `files_modified`** (un autre nœud
peut écrire dans le même arbre) — jamais un `git diff <base> HEAD`, qui n'a aucun référent puisque
la tâche ne produit pas de commit.
