---
name: vf-spec
description: >
  Utiliser quand il faut **figer le QUOI** avant de discuter du comment — « qu'est-ce que
  ça doit faire exactement ? », « fige le périmètre », « écris la spec », « on se met
  d'accord sur le contrat avant de coder », « c'est quoi le comportement attendu », « liste
  les cas limites ». Produit un contrat de comportement explicite : périmètre, cas
  nominaux, cas limites, ce qui est hors sujet.
  ✘ pas pour le COMMENT et le découpage en tâches → /vf-plan · ✘ pas pour l'idéation amont
  sur une idée floue → /vf-explore · ✘ pas pour concevoir la solution technique →
  /vf-brainstorm · ✘ pas pour répondre à la question par du code jetable → /vf-spike ·
  ✘ pas pour documenter ce qui existe déjà → /vf-docs.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-spec — Périmètre figé

Délègue à `gsd-spec-phase` : rédaction du contrat de comportement d'une étape — ce que ça doit
faire, dans quelles limites, et ce qui est explicitement hors périmètre.

Reframe toute sortie en vocabulaire VibeFlow : « spec-phase » → **périmètre figé**, « phase » →
**étape/sprint**, « scope » → **périmètre** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni
`gsd-spec-phase` à l'utilisateur.

Frontière avec `/vf-plan` : ici on écrit **le QUOI** (comportement attendu, critères
d'acceptation) ; là-bas on écrit **le COMMENT** (tâches, ordre, dépendances). Un plan sans QUOI
figé dérive ; un QUOI figé sans plan ne s'exécute pas.

Enchaînement typique : `vf-explore` ou `vf-brainstorm` → `vf-spec` (on fige) → `vf-plan` (on
découpe) → `vf-execute`.
