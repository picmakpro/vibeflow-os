---
name: archivage-auto-dans-l-arbre-partage
description: la garde de fin de geste de la session principale lance check-method-budget.sh --auto dans l'arbre commun ; un diff ROADMAP/.planning/archives non produit par la mission n'est jamais à commiter
metadata:
  type: project
---

Le 2026-10-10, pendant la planification de la 57, un archivage SOBR-06 a retiré 1393 lignes du ROADMAP fiabilite (bloc fiabilite-v1.0) et posé l'archive et INDEX.tsv, sans commit. C'est le Stop de la session principale qui l'avait déclenché, via la sentinelle armée par #128. Je l'ai commité, alors que l'archive était fidèle : le dépôt est passé rouge sur check-divergence S4(a), car les dossiers de phase existaient encore. Samuel a fait revert, puis le correctif a été mergé (#143, conductor v1.48.2 : un bloc dont les dossiers de phase existent est refusé).

**Why:** une archive fidèle n'est pas une archive légitime. Le diff venait d'un autre acteur, et la règle qui l'a produit était fausse.

**How to apply:** avant chaque commit, `git status`. Tout diff sous `.planning/archives/`, ou tout diff du ROADMAP que mes dispatches n'ont pas produit, se `git restore` et se rapporte ; je ne le commite jamais. Ajouter les fichiers par chemin. Rejouer `check-divergence.sh` (rc lu sans pipe) avant le push. Voir [[project_sessions-concurrentes-sur-le-repo]].
