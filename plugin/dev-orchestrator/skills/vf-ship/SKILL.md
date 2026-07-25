---
name: vf-ship
description: >
  Utiliser quand **ton** travail est validé et prêt à partir — « crée une PR », « livre »,
  « ship », « mets en prod », « pousse », « ouvre la pull request », « sors une branche
  propre ». Crée la PR, lance la revue et prépare le merge après recette.
  ✘ pas pour trier les issues et PR **entrantes** du dépôt → /vf-inbox · ✘ pas pour couper
  la session en gardant le contexte → /vf-pause · ✘ pas pour clore un jalon entier →
  /vf-milestone.
  Invocable par l'utilisateur ET par l'agent en autonomie (après vf-test/vf-review).
---

# vf-ship — Livraison

Invoque le skill **`gsd-ship`** (crée la PR, lance la revue, prépare le merge).

**Variante — préparation d'une branche de PR propre.** Quand la demande porte sur la branche
elle-même (« sors une branche propre », « la PR ne doit pas embarquer les commits de suivi »),
délègue d'abord à **`gsd-pr-branch`** : il produit une branche filtrée des commits d'artefacts de
planification. La livraison enchaîne ensuite normalement sur `gsd-ship`.

Reframe toute sortie en vocabulaire VibeFlow : « ship » → **livraison**, « PR branch » →
**branche de livraison** (cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Pré-requis : la **recette** (`vf-test`) doit être passée avant de livrer.
