---
name: vf-cleanup
description: >
  Utiliser quand les dossiers d'étapes s'accumulent et qu'il faut ranger — « fais le
  ménage », « archive les vieux dossiers d'étapes », « y a trop de vieux sprints qui
  traînent », « range les étapes terminées », « nettoie tout ce qui est fini ». Archive les
  dossiers d'étapes des jalons déjà clos pour garder un espace de travail lisible.
  ✘ pas pour clore un jalon (audit + bilan + archivage) → /vf-milestone · ✘ pas pour
  annuler du travail → /vf-undo · ✘ pas pour retirer une étape de la feuille de route →
  /vf-phase · ✘ pas pour le socle de suivi d'un lab non-dev → /vf-planning.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-cleanup — Ménage du suivi

Délègue à `gsd-cleanup` : archivage des dossiers d'étapes accumulés sur les jalons déjà terminés.

Reframe toute sortie en vocabulaire VibeFlow : « cleanup » → **ménage**, « phase directories » →
**dossiers d'étapes**, « milestone » → **jalon** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni
`gsd-cleanup` à l'utilisateur.

**On archive, on ne supprime pas** : rien de ce qui a été décidé ne doit devenir irretrouvable.

Enchaînement typique : `vf-milestone` (clôture du jalon) → `vf-cleanup` (rangement) →
`vf-milestone` (ouverture du suivant).
