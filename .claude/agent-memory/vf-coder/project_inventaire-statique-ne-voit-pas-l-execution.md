---
name: inventaire-statique-ne-voit-pas-l-execution
description: Un inventaire statique de chaînes d'interface vert (F2) laisse passer l'anglais composé à l'exécution et les nœuds morcelés par un autre script ; contrôle visuel navigateur obligatoire.
metadata:
  type: project
---

Phase 67-07 (cockpit en français) : le test d'inventaire du rendu servi est resté vert alors que le navigateur montrait encore de l'anglais : pluriels composés (`files`), texte morcelé par le glossaire (microtâche avant la traduction), libellés d'attribut assemblés (`Health check: nothing urgent`).

**Why:** une chaîne vue seulement à l'exécution n'est pas un littéral du source ; un vert statique ne prouve pas « zéro anglais visible ».
**How to apply:** après tout test d'inventaire de chaînes, parcourir les panneaux dans un vrai navigateur (playwright) et lister les nœuds de texte qui ressemblent à de l'anglais ; traduire AVANT tout script qui découpe le DOM (écouteurs synchrones, pas observateur différé). Un mutant « garde retirée » peut rester vert quand la garde est redondante : le dire, ne pas l'inventer discriminant. Détail aussi : le rendu est renommé à l'assemblage, donc chercher le nom amont dans les SOURCES, pas seulement dans la page servie. Voir [[feedback_existence-au-lieu-de-relation]].
