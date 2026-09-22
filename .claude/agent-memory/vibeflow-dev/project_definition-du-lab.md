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

Voir [[loi-etat-derive-du-disque]] et [[verifier-fraicheur-avant-audit]].
