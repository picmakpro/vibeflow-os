---
name: assouplir-garde-muter-clause-voisine
description: Phase 60 tour 2 - apres un assouplissement de conduite (rc 3/64 continuent), muter la clause VOISINE inchangee (rc 5) et rejouer le moteur reel sur les layouts hors gabarit
metadata:
  type: feedback
---

Quand un correctif assouplit une clause de consommateur (ici `Codes 3 et 64` -> le cycle continue), les mutants
ajoutes ne gardent que la clause modifiee. La clause voisine laissee « inchangee » (`Code 5` -> human_needed / s'arreter)
n'a aucun mutant : `Code 5 : le cycle continue` survit a la suite T45 (429 OK / 2 KO identiques, les 2 KO etant
environnementaux : `.planning/config.json` absent de `git archive`). Preuve : perl -pi sur la copie `git archive`, rejeu
de test-dev-orchestrator.sh (~56 s).

**Why:** la propriete qui compte apres un assouplissement est celle qui reste stricte ; c'est la seule non mesuree.

**How to apply:** pour toute clause prose gardee par literaux + ordre + `t45_clause_continue`, muter la clause adjacente
non touchee (vf-coder.md ET vf-auto/SKILL.md) avant de conclure « garde dans les deux sens ».

Deuxieme piege du meme tour : « aligne sur gsd-core `stripShippedMilestones` » n'implique pas que `roadmap get-phase`
rende la meme visibilite. Avec une ligne bullet de jalon `- 🚧 **v2.0** - Phases 5-6 (in progress)` plus un `<details>`
nu de jalon actif, gsd rend `found: true` et le gate (qui cache tout `<details>` exact) rend rc 3. Rejouer
`gsd-tools.cjs roadmap get-phase` sur des layouts hors gabarit, pas seulement le gabarit de templates/roadmap.md.
