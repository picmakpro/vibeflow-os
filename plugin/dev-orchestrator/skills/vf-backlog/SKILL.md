---
name: vf-backlog
description: >
  Utiliser pour capturer ou trier ce qu'on ne fait pas maintenant — « note cette idée »,
  « garde ça pour plus tard », « mets-le au backlog », « qu'est-ce qu'il y a dans le
  backlog ? », « promeus cet item en étape », « range ça quelque part », « j'ai une idée
  mais on la traite pas tout de suite ». Capture l'item au bon endroit, puis permet de
  revoir la réserve et d'en promouvoir une partie dans la feuille de route.
  ✘ pas pour creuser une idée encore floue → /vf-explore · ✘ pas pour trier les issues et
  PR entrantes du dépôt → /vf-inbox · ✘ pas pour cadrer un lot de travail à faire →
  /vf-plan.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-backlog — Réserve d'idées & de tâches

Délègue, selon le geste :

- `gsd-capture` — **poser** une idée, une note, une tâche ou une graine à sa bonne destination,
  sans interrompre le travail en cours ;
- `gsd-review-backlog` — **revoir** la réserve, la trier, et promouvoir ce qui mérite d'entrer
  dans la feuille de route.

Reframe toute sortie en vocabulaire VibeFlow : « backlog » → **réserve**, « capture » → **prise de
note**, « seed » → **graine d'idée** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni ces cibles
à l'utilisateur.

Capturer ne coûte rien et n'engage rien : c'est le geste qui évite d'ouvrir un chantier parasite au
milieu d'un autre.

Enchaînement typique : `vf-backlog` (on capture au fil de l'eau) → `vf-backlog` (revue de la
réserve) → `vf-phase` ou `vf-plan` (ce qu'on promeut).
