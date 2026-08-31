---
name: gate-qui-balaie-le-depot-se-balaie-lui-meme
description: Un gate qui scanne les fichiers versionnés scanne aussi son propre script et sa suite — prévoir l'auto-exemption AVANT d'écrire, jamais après coup par une exception
metadata:
  type: feedback
---

Un gate dont l'univers est « les fichiers suivis du dépôt » **inclut son propre code et sa propre
suite de tests**. Les deux ont besoin d'écrire le motif interdit pour exister.

**Why** : mesuré le 2026-08-05 sur `scripts/check-machine-paths.sh`. La suite a fait rougir le gate
dès sa pose — non par une fixture, mais par une **phrase de son en-tête** qui citait le motif pour
expliquer pourquoi on ne l'écrit pas. Le réflexe est alors d'ajouter une exception « pour la suite » :
c'est **commencer à trouer le gate par son test**, et cette porte-là ne se referme jamais.

**How to apply**, dans cet ordre :
1. **Le script du gate** : construire le motif recherché par assemblage, de sorte que sa source ne
   contienne jamais la forme complète (`/(Users|home)/` en regex ne matche pas `/Users/` littéral).
   L'auto-passage devient structurel, pas conventionnel.
2. **La suite** : assembler les littéraux fautifs **à l'exécution** (`U="/Users"; "$U/alice/x"`).
   Aucune exception à écrire.
3. **Le cas résiduel** — une phrase de doc où le littéral EST le sujet : c'est le seul emploi
   légitime de l'échappatoire par marqueur de **ligne** (jamais de fichier : une amnistie de fichier
   est une porte). Effet secondaire utile : l'échappatoire cesse d'être un mécanisme que seules les
   fixtures exercent.
4. **Toujours** un cas de mutation qui prouve que l'échappatoire est **réellement consultée**
   (marqueur retiré → le vert doit virer au rouge). Sans lui, elle laisse passer parce que rien ne
   la regarde, et la suite ne sait pas faire la différence.

Voisines : [[feedback-mutation-test-discriminating-cases]], [[feedback-gate-jamais-de-repli]],
[[feedback-existence-au-lieu-de-relation]].
