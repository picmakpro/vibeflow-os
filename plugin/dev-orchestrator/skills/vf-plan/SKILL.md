---
name: vf-plan
description: >
  Utiliser quand l'utilisateur veut cadrer puis structurer **le contenu d'un lot de
  travail** — « planifie », « découpe », « prépare le sprint », « cadre cette feature »,
  « on attaque quoi ? », « structure le boulot », « la plus petite version qui marche ».
  La demande peut être encore floue : le cadrage précède le plan.
  ✘ pas pour éditer la feuille de route elle-même (ajouter, insérer, réordonner une étape)
  → /vf-phase · ✘ pas pour figer le QUOI et les cas limites → /vf-spec · ✘ pas pour poser
  le socle documentaire d'un lab non-dev (structurer la doc, poser le cadre du lab) →
  /vf-planning.
  Invocable par l'utilisateur ET par l'agent en autonomie (avant vf-execute).
---

# vf-plan — Cadrage puis plan de travail

Invoque d'abord **`gsd-discuss-phase`** (cadrage), puis **`gsd-plan-phase`** (plan de travail).
Ne jamais planifier dans le vide : si la demande est floue, le cadrage est obligatoire.

**Variante — la version minimale qui marche.** Quand la demande porte explicitement sur la plus
petite tranche livrable (« le MVP de cette étape », « juste ce qui marche », « une tranche
verticale »), délègue à **`gsd-mvp-phase`** au lieu du plan complet : même geste, périmètre
resserré à la valeur minimale démontrable.

Reframe toute sortie en vocabulaire VibeFlow : « PLAN » → **plan de travail**,
« phase » → **étape/sprint**, « discuss » → **cadrage**, « MVP phase » → **version minimale qui
marche** (cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Étape suivante naturelle : **`vf-execute`**.
