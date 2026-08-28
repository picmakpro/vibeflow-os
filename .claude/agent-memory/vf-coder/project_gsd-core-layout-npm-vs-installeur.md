---
name: gsd-core-layout-npm-vs-installeur
description: Le paquet npm @opengsd/gsd-core ne pose PAS son payload sous node_modules/@opengsd/gsd-core/bin/lib — seul l'installeur officiel (--claude --global|--local) le dépose là où les cascades du repo le cherchent
metadata:
  type: project
---

Poser `gsd-core` pour un gate ou une CI passe **obligatoirement par l'installeur officiel**
(`npx -y "@opengsd/gsd-core@^1" --claude --global` ou `--local`), **jamais** par un
`npm install @opengsd/gsd-core`.

**Why:** mesuré le 2026-08-03 sur la version 1.9.1. Le tarball publié range ses modules sous
`node_modules/@opengsd/gsd-core/`**`gsd-core/bin/lib/`** (double segment). Un `bin/lib/` existe
bien un cran plus haut, mais il ne contient que `ui-safety-gate.cjs` — pas `config.cjs`. Or les
cascades de résolution du dépôt (`check-gsd-config.sh`, et la cascade `$S` de `mission-flow.md`)
cherchent `<repo>/node_modules/@opengsd/gsd-core/bin/lib` : **cette branche n'est donc jamais
satisfaite par un `npm install`**. Elle a l'air correcte à la lecture, elle ne résout rien à
l'exécution. L'installeur, lui, dépose l'arborescence attendue sous
`$HOME/.claude/gsd-core/` (`--global`) ou `<repo>/.claude/gsd-core/` (`--local`).

**How to apply:**

- Cibler la branche `$HOME/.claude/gsd-core/bin/lib` par défaut : c'est la topologie d'un poste
  réel, et elle ne dépose rien dans l'espace de travail.
- Sur **vibeflow-os**, la branche `<repo>/.claude/gsd-core` est à écarter : le `.gitignore` ignore
  `.claude/` délibérément (« le repo est la SOURCE des modules, PAS un lab »), et y installer
  déplacerait le `GSD_HOME` dérivé par `check-gsd-engine.sh` / `ensure-deps.sh`.
- Toujours **asserter l'existence des 4 modules** (`config.cjs`, `config-loader.cjs`,
  `capability-registry.cjs`, `configuration.cjs`) après l'install : l'installeur peut sortir 0
  sans avoir posé le payload attendu, et l'échec se manifesterait alors très loin de sa cause.
- Prérequis dur : **Node ≥ 22**. Version en cours d'usage sur le poste de Samuel : 1.9.0 ;
  `^1` résout 1.9.1 aujourd'hui (les deux passent l'égalité d'ensemble du cas 26).

Voir [[check-agents-scope]] pour l'autre piège du même genre : un gate qui a l'air de couvrir une
cible alors qu'il regarde ailleurs.
