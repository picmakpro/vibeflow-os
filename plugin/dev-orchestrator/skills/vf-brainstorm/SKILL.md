---
name: vf-brainstorm
description: >
  Utiliser quand l'idée est **déjà formulée** et qu'il faut concevoir la solution avant de
  s'engager — « réfléchis à comment on ferait ça », « on part sur quoi ? », « et si on… »,
  « conçois-moi une solution », « imagine comment on s'y prend », « quelles options pour
  faire ça », « brainstorm ». Aucune décision d'implémentation n'est encore prise : on
  dessine le comment sur le papier.
  ✘ pas pour une idée encore floue à débroussailler → /vf-explore · ✘ pas pour expérimenter
  avec du code jetable → /vf-spike · ✘ pas pour figer le QUOI → /vf-spec · ✘ pas pour
  trancher entre deux options déjà identifiées → /vf-decide.
  Invocable par l'utilisateur ET par l'agent en autonomie (en amont de vf-plan).
---

# vf-brainstorm — Conception de solution

Invoque le skill **`brainstorming`** (Superpowers) : on part d'une idée **déjà formulée** et on
dessine le comment.

Reframe toute sortie en vocabulaire VibeFlow : on parle de **conception de solution**, jamais de
« brainstorming » au sens outil interne (cf. `vocabulary-map.md`). Le label **idéation** appartient
à `vf-explore` (idée encore floue) — l'emprunter recollerait deux gestes que les descriptions
viennent de départager.
Ne nomme jamais GSD ni Superpowers.

Étape suivante naturelle une fois la solution dessinée : **`vf-spec`** (figer le QUOI) puis
**`vf-plan`**.
