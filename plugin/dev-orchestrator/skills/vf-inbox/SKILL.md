---
name: vf-inbox
description: >
  Utiliser quand il faut traiter ce qui arrive de l'extérieur sur le dépôt — « trie les
  issues », « y a quoi dans les PR en attente ? », « regarde les tickets ouverts »,
  « qu'est-ce qu'on m'a envoyé sur le repo », « fais le tri dans la inbox GitHub »,
  « réponds aux issues ». Passe les issues et pull requests ouvertes au filtre des
  templates et des règles de contribution du projet, puis propose un traitement par item.
  ✘ pas pour ouvrir une PR sur ton propre travail → /vf-ship · ✘ pas pour ranger tes idées
  internes → /vf-backlog · ✘ pas pour relire le code d'un diff → /vf-review.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-inbox — Tri des issues & PR entrantes

Délègue à `gsd-inbox` : revue des issues et pull requests ouvertes contre les templates du dépôt et
les règles de contribution, avec une recommandation par item.

Reframe toute sortie en vocabulaire VibeFlow : « inbox » → **arrivées du dépôt**, « triage » →
**tri** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-inbox` à l'utilisateur.

Rien n'est fermé, mergé ni répondu sans validation humaine (ADR-031) : le tri **propose**.

Enchaînement typique : `vf-inbox` (ce qui mérite d'être traité) → `vf-backlog` (ce qu'on garde
pour plus tard) → `vf-plan` (ce qu'on prend maintenant).
