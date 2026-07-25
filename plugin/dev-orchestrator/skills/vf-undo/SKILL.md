---
name: vf-undo
description: >
  Utiliser quand il faut défaire du travail déjà produit — « annule », « reviens en
  arrière », « rollback », « défais ce qu'on vient de faire », « oublie cette étape, on
  repart d'avant », « remets comme c'était ». Rembobine le travail d'une étape (code et
  artefacts de suivi) de façon cohérente, sous confirmation.
  ✘ pas pour reprendre le fil d'une session passée → /vf-resume · ✘ pas pour retirer une
  étape de la feuille de route sans toucher au code → /vf-phase · ✘ pas pour comprendre
  pourquoi ça a échoué → /vf-forensics.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-undo — Retour arrière

Délègue à `gsd-undo` : rembobinage cohérent du travail d'une étape — code **et** artefacts de
suivi remis dans un état antérieur consistant.

Reframe toute sortie en vocabulaire VibeFlow : « undo / rollback » → **retour arrière**,
« phase » → **étape/sprint** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-undo` à
l'utilisateur.

**Geste destructeur** : toujours confirmer le périmètre exact avant d'agir (ADR-031). Jamais en
autonomie non supervisée sans point d'arrêt explicite.

Enchaînement typique : `vf-forensics` (comprendre d'abord) → `vf-undo` (rembobiner) → `vf-plan`
(repartir sur de bonnes bases).
