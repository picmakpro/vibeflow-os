---
name: vf-sketch
description: >
  Utiliser quand l'utilisateur veut **voir** une idée d'écran avant de s'engager —
  « maquette-moi ça », « une idée d'écran », « mockup jetable », « montre-moi à quoi ça
  ressemblerait », « esquisse deux ou trois variantes », « fais-moi voir vite fait », « je
  visualise pas, dessine ». Produit des maquettes jetables et sacrifiables dont le seul
  rôle est de trancher une direction visuelle — pas d'entrer en production.
  ✘ pas pour définir la direction artistique ou refondre une interface réelle → /vf-design ·
  ✘ pas pour expérimenter du code fonctionnel jetable → gsd-spike · ✘ pas pour construire
  l'écran pour de vrai → gsd-execute-phase.
  Invocable par l'utilisateur ET par l'agent en autonomie (typiquement par le routeur design
  avant de trancher une direction).
---

# vf-sketch — Maquette jetable

Délègue à `gsd-sketch` : génération de maquettes jetables (et, en mode frontière, proposition de
variantes à explorer) pour rendre une idée d'interface visible et comparable.

Reframe toute sortie en vocabulaire VibeFlow : « sketch » → **maquette jetable**, « mockup » →
**esquisse** (cf. `design-vocabulary-map.md`). Ne nomme jamais les outils design internes bruts
à l'utilisateur.

**La maquette se jette.** Elle sert à choisir, pas à livrer : une fois la piste retenue, la mise en
œuvre passe par `/vf-design` (direction artistique, système de design, craft) puis par le cycle de
développement normal.

Frontière avec `gsd-spike` (chaîne dev, si elle est installée) : le jetable est **visuel** ici (à
quoi ça ressemblerait), **fonctionnel** là-bas (est-ce que ça marche techniquement).

Enchaînement typique : `vf-sketch` (on voit les options) → `/vf-design` (on cadre et on craft) →
`gsd-execute-phase` (le cycle de développement construit pour de vrai).
