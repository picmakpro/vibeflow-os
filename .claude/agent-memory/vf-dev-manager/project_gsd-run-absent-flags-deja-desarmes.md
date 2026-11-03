---
name: gsd-run-absent-flags-deja-desarmes
description: Reset des flags d'enchaînement sur vibeflow-os — `gsd-run.sh config-set --ws` crée un config.json de compartiment qui masque la racine ; les flags sont déjà false à la racine
metadata:
  type: project
---

Le reset de démarrage passe aujourd'hui par `plugin/dev-orchestrator/scripts/gsd-run.sh config-set …`
(l'ancien `gsd_run` nu n'existait pas, constaté le 2026-08-16). Le 2026-11-02, `config-set --ws fiabilite`
a **créé** `.planning/workstreams/fiabilite/config.json` (non suivi, deux clés seulement) : un fichier de
compartiment qui peut masquer tout le `.planning/config.json` racine pour ce compartiment. Les deux flags
valaient déjà `false` à la racine.

**Why:** le geste prescrit « désarmer » fabrique un artefact d'état neuf, invisible tant qu'on ne relit
pas `git status`, et qui changerait la configuration effective du moteur pour tout le compartiment.

**How to apply:** avant le `config-set`, lire `workflow._auto_chain_active` et `workflow.auto_advance`
par `gsd-run.sh config-get` (même `--ws`). S'ils valent déjà `false`, ne pas écrire. Si un `config-set` a
créé `.planning/workstreams/<ws>/config.json`, le supprimer (artefact de la mission) puis relire
`config-get` → `false`. Le signaler au rapport. Voir [[resolution-scripts-sur-le-repo-source]].
