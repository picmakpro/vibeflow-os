---
name: gsd-run-absent-flags-deja-desarmes
description: Sur vibeflow-os, `gsd_run config-set` n'existe pas comme commande shell — le reset des flags d'enchaînement se vérifie par lecture de .planning/config.json
metadata:
  type: project
---

Le geste de démarrage « `gsd_run config-set workflow._auto_chain_active false` puis
`workflow.auto_advance false` » échoue systématiquement dans ce repo : `gsd_run` n'est pas résolu
(`command not found`), ni comme binaire ni comme fonction de shell. Constaté le 2026-08-16
(mission Phase 31), sur une machine où gsd-core est pourtant installé.

**Why:** la doctrine du manager impose ce reset avant le premier dispatch, et son échec ressemble à
un défaut d'outillage bloquant alors que les deux flags sont déjà persistés à `false` dans
`.planning/config.json` (bloc `workflow`) — ils y survivent aux sessions.

**How to apply:** tenter la commande en best-effort, puis **vérifier par lecture** de
`.planning/config.json` que `workflow._auto_chain_active` et `workflow.auto_advance` valent bien
`false`. Si oui, consigner « déjà désarmés, vérifiés par lecture » au rapport et enchaîner — ne pas
escalader, ne pas éditer le fichier à la main. Voir aussi [[resolution-scripts-sur-le-repo-source]]
pour la résolution de `$S` dans le même geste de démarrage.
