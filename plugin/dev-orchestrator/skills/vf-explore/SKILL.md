---
name: vf-explore
description: >
  Utiliser quand l'idée est encore **floue** et qu'il faut la débroussailler par le
  dialogue — « explore cette idée », « je sais pas encore ce que je veux », « creuse le
  sujet », « aide-moi à y voir clair », « j'ai un truc en tête mais c'est vague »,
  « pose-moi des questions », « on sait pas trop où on va avec ça ». Idéation socratique :
  on questionne jusqu'à ce que l'intention devienne formulable, puis on route.
  ✘ pas pour concevoir une solution sur une idée **déjà formulée** → /vf-brainstorm ·
  ✘ pas pour expérimenter avec du code jetable → /vf-spike · ✘ pas pour figer le QUOI →
  /vf-spec · ✘ pas pour trancher entre deux options identifiées → /vf-decide.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-explore — Idéation socratique

Délègue à `gsd-explore` : idéation par questionnement et routage de l'idée — on pense l'idée
**avant** de s'engager sur quoi que ce soit de structuré.

Reframe toute sortie en vocabulaire VibeFlow : « explore » → **idéation**, « idea routing » →
**orientation de l'idée** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-explore` à
l'utilisateur.

Position dans le quatuor amont — c'est le **plus en amont** des quatre :

| Verbe | Ce qu'on a en entrée | Ce qu'on produit |
|---|---|---|
| `/vf-explore` | une intuition floue | une intention formulable |
| `/vf-brainstorm` | une idée formulée | une solution conçue |
| `/vf-spike` | une hypothèse technique | une réponse, du code jeté |
| `/vf-spec` | un accord de principe | le QUOI figé |

Enchaînement typique : `vf-explore` → `vf-brainstorm` → `vf-spec` → `vf-plan`.
