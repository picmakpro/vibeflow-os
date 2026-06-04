---
name: vf-plan
description: >
  Utiliser quand l'utilisateur veut cadrer puis structurer un lot de travail — « planifie »,
  « découpe », « prépare le sprint », « cadre cette feature », « on attaque quoi ? »,
  « structure le boulot ». La demande peut être encore floue : le cadrage précède le plan.
  Invocable par l'utilisateur ET par l'agent en autonomie (avant vf-execute).
---

# vf-plan — Cadrage puis plan de travail

Invoque d'abord **`gsd-discuss-phase`** (cadrage), puis **`gsd-plan-phase`** (plan de travail).
Ne jamais planifier dans le vide : si la demande est floue, le cadrage est obligatoire.

Reframe toute sortie en vocabulaire VibeFlow : « PLAN » → **plan de travail**,
« phase » → **étape/sprint**, « discuss » → **cadrage** (cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Étape suivante naturelle : **`vf-execute`**.
