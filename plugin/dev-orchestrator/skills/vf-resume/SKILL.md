---
name: vf-resume
description: >
  Utiliser quand on revient sur un travail interrompu et qu'il faut **recharger le
  contexte** d'une session passée — « on reprend », « reprends où on en était », « recharge
  le contexte », « rappelle-moi où on s'était arrêtés », « je reviens après une semaine »,
  « t'as tout perdu, remets-toi dedans ». Restitue l'état de la session précédente : ce qui
  était en cours, ce qui restait à faire, les décisions déjà prises.
  ✘ pas pour un point d'avancement / savoir ce qui vient après → /vf-progress · ✘ pas pour
  noter où on s'arrête avant de couper → /vf-pause · ✘ pas pour annuler du travail →
  /vf-undo.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-resume — Reprise de contexte

Délègue à `gsd-resume-work` : restauration complète du contexte d'une session interrompue —
travail en cours, reste à faire, décisions déjà arbitrées.

Reframe toute sortie en vocabulaire VibeFlow : « resume-work » → **reprise de contexte**,
« handoff » → **passation**, « phase » → **étape/sprint** (cf. `vocabulary-map.md`). Ne nomme
jamais GSD ni `gsd-resume-work` à l'utilisateur.

Frontière avec `/vf-progress` : ici on **recharge ce qu'on savait** ; là-bas on **mesure où en est
le projet**. Après une longue coupure, les deux s'enchaînent.

Enchaînement typique : `vf-pause` (fin de session précédente) → `vf-resume` (retour) →
`vf-progress` → le verbe du geste en cours.
