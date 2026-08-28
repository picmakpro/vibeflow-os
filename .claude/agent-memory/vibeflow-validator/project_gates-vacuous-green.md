---
name: gates-vacuous-green
description: Sur le repo de distribution vibeflow-os, les gates du repo sortent exit 0 sans rien vérifier — ne jamais prendre leur vert pour une conformité
metadata:
  type: project
---

Les gates de `vibeflow-os` scannent en dur une arborescence de **lab** (`.claude/agents`,
`.claude/skills`, `.claude/scripts`). Sur le **repo de distribution**, ces répertoires n'existent
pas : les gates sortent « rien à vérifier », **exit 0**. Constaté 2026-07-25 sur `check-agents.sh`
(même en `--strict`), `check-debug-research.sh`, `audit-infra.sh`, `probe-memory-guards.sh`
(silence = « tout va bien »), `check-file-size.sh` sans argument, et `check-version-sync.sh` (compte
les fichiers `module.json`, ne lit jamais `plugin/*/VERSION`).

**Why:** c'est un unique bug de conception répété — *cible absente = cible conforme*. Il a laissé
passer des défauts réels (agent avec skills fantômes, README périmé sur 13 versions) pendant
13 releases. Le repo a pourtant l'axiome qui l'interdit
(`AXIOMES-ENFORCEMENT.md` : « un filet décoratif est pire que pas de filet »).

**How to apply:** en phase 1/2/4 d'un audit de ce repo, **ne jamais reporter un vert de gate sans
avoir vérifié qu'il a trouvé des cibles**. Pointer explicitement les outils :
`check-agents.sh --strict --agents-dir=plugin/<mod>/agents` (le flag existe et fonctionne, rien ne
l'utilise). Un « aucun X — rien à vérifier » est un **INDÉTERMINÉ**, à reporter comme finding, pas
comme conformité.

Voir [[validator-skills-fantomes]] — c'est ce même gate qui aurait dû attraper ce défaut, mais il
ne le classe qu'en WARNING (ERROR seulement sous `--strict`, jamais invoqué).
