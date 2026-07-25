---
name: vf-milestone
description: >
  Utiliser quand on ouvre, clôt ou fait le bilan d'un **jalon** (une version du produit) —
  « on ouvre une nouvelle version », « on clôt ? », « archive le jalon », « bilan de la
  v2 », « on passe à la suite du produit », « la milestone est finie », « qu'est-ce qu'on
  a vraiment livré sur cette version ». Couvre l'ouverture, la clôture avec archivage, le
  bilan et l'audit d'un jalon contre son intention d'origine.
  ✘ pas pour ajouter / réordonner une étape dans la feuille de route → /vf-phase · ✘ pas
  pour archiver les vieux dossiers d'étapes → /vf-cleanup · ✘ pas pour savoir où on en est
  aujourd'hui → /vf-progress.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-milestone — Cycle de vie d'un jalon

Délègue, selon le moment du cycle :

- `gsd-new-milestone` — **ouvrir** un jalon (nouvelle version, nouveau lot d'exigences) ;
- `gsd-complete-milestone` — **clore** et archiver un jalon terminé, préparer le suivant ;
- `gsd-milestone-summary` — produire le **bilan** de ce qui a été livré ;
- `gsd-audit-milestone` — **auditer** la complétude du jalon contre son intention d'origine, avant
  archivage.

Reframe toute sortie en vocabulaire VibeFlow : « milestone » → **jalon**, « phase » →
**étape/sprint**, « summary » → **bilan de jalon** (cf. `vocabulary-map.md`). Ne nomme jamais GSD
ni ces cibles à l'utilisateur.

Ordre canonique de clôture : **auditer** → **bilan** → **clore**. On n'archive pas un jalon dont
l'audit remonte des manques — ceux-là partent en `vf-gaps`.

Enchaînement typique : `vf-gaps` → `vf-milestone` (audit + bilan + clôture) → `vf-cleanup`.
