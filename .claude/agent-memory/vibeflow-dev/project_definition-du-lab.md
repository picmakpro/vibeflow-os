---
name: definition-du-lab
description: Ce qu'est un lab pour Willy — agents + mémoire + objectif propre — et pourquoi les labs emboîtés sont légitimes
metadata:
  type: project
---

**Un lab est un dossier qui porte des agents et de la mémoire, avec un objectif propre.** C'est le
`.claude/` habité qui fait le lab, pas le dépôt git. **Des labs peuvent donc être emboîtés**, et
chacun a droit à son `.planning/`.

**Why:** énoncé par Willy le 2026-09-22 pour corriger une erreur d'analyse. J'avais lu
`jarvis-keystone` comme *un* lab portant six plannings, et une passe adversariale avait chiffré à
**5 665 références dans 1 302 fichiers** le coût de leur fusion. La prémisse était fausse : Keystone
est **six labs emboîtés** (racine, doctrine, pilotage, atelier marché-offre, captation, gabarit), et
la correspondance `.claude/` ↔ `.planning/` y est **parfaite, 6 sur 6, zéro orphelin**. Aucune
migration n'était due.

**La preuve par l'absurde est sur BusinessFlow-Lab.** Sa racine est un vrai lab (17 agents +
mémoire) et son planning vit. Quatre compartiments portent un `.planning/` **sans être des labs** —
`projects/avma`, `projects/dmflow`, `projects/lead-recovery` (aucun `.claude/`) et
`projects/formation` (un `.claude/` mais zéro agent). **Ce sont exactement les quatre plannings
morts**, tous figés à `last_updated: 2026-06-23`. Un planning qu'aucun agent n'habite ne peut pas
vivre.

**How to apply:** avant de conclure quoi que ce soit sur la topologie d'un dépôt, compter les
`.claude/` habités, pas les dossiers. Le critère est binaire et vérifiable par machine : un
`.planning/` est légitime s'il est à la racine d'un lab (`.claude/` avec agents et mémoire) ou d'un
projet de code (`gsd_state_version`). Tout autre est orphelin — et un orphelin est un planning qui
mourra. Corollaire de méthode : une passe adversariale hérite des prémisses fausses de ce qu'elle
audite ; elle vérifie des affirmations, elle ne rattrape pas un cadrage erroné.

**La frontière d'un lab est un objectif, pas un métier.** Précisé par Willy le 2026-09-23 :
BusinessFlow-Lab réunit un commercial, un juriste, un financier — plusieurs métiers, **un seul
objectif**, faire tourner son business. Ses deux erreurs de structure (un compartiment de création
de produits, un compartiment de formation) ne sont pas des erreurs de taille mais **des objectifs
différents logés au même endroit**. Le test qui en découle : *« si l'objectif principal
disparaissait, ce sous-objectif aurait-il encore un sens ? »* — non, même lab ; oui, lab à part, ou
lab emboîté si c'est lié. Et un lab « trop gros » est un lab mal architecturé : le savoir volumineux
va dans une base interrogeable (FileFlow), jamais réparti dans des skills.

**How to apply (suite) :** avant de proposer de découper ou de fusionner des labs, raisonner en
objectifs, jamais en nombre de livrables ou d'agents. Un lab à beaucoup de livrables est sain s'ils
servent tous la même finalité.

Voir [[loi-etat-derive-du-disque]] et [[verifier-fraicheur-avant-audit]].
