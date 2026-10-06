---
name: gate-touche-un-chemin-par-trailer
description: Un trailer Gate-Touche = UN chemin, sans virgule ; 45-CONTROLE-MARQUEUR juge commit par commit et une lecture de plus dans le cœur exige une ligne de RECENSEMENT_LECTURE.
metadata:
  type: project
---

Un trailer `Gate-Touche: a, b — raison` est « mal formé » (motif à virgule) : `check-gate-touche.sh` rend quand même rc=0 (DECLARE), mais `45-CONTROLE-MARQUEUR.sh` compte le commit « sans-marqueur » et ne se rattrape pas par un commit ultérieur.

**Why:** fix-46-c (2026-10-06) : 7 commits fautifs, réparés par réécriture de messages (accord du manager, ref de sauvegarde, commit-tree + update-ref) alors que le worktree portait un fichier modifié d'un autre.

**How to apply:** un trailer par chemin dès le premier commit. Toute nouvelle fonction qui lit un fichier dans planning-hook.sh s'inscrit dans `RECENSEMENT_LECTURE` (test-planning-gates.sh) avec sa borne, sinon R-LECTURE-RECENSEMENT et son mutant rougissent.
