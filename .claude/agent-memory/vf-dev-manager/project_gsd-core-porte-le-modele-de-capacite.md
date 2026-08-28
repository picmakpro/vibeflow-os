---
name: gsd-core-porte-le-modele-de-capacite
description: gsd-core embarque déjà un modèle de capacité runtime à 9 axes + degradationFor ; tout enum maison full/skills-only/unsupported le réimplémente en le dégradant
metadata:
  type: project
---

`~/.claude/gsd-core/bin/lib/host-integration.cjs` (mesuré sur 1.11.0, 2026-08-28) définit déjà un
modèle de capacité runtime complet : **9 axes** (`embeddingMode`, `commandSurface`,
`dispatch{namedDispatch,nested,maxDepth,background,subagentToolkit,backgroundDispatch,isolation}`,
`modelMode`, `hookBus`, `stateIO`, `transport`, `runtime`, `effortSurface`), **6 points
d'interface** (`command|dispatch|model|hooks|state|artifact`), **3 profils**
(`programmatic-cli`/`declarative-cli`/`ide`), un `SAFE_DEFAULTS` fail-closed, et une fonction
`degradationFor(point, axes)` qui rend un niveau de dégradation **par point d'interface**.
Registre des runtimes : `bin/shared/runtime-aliases.manifest.json`. Surfaces de hooks écrites par
gsd-core pour 4 runtimes : `bin/lib/runtime-hooks-surface.cjs`.

Côté VibeFlow, **rien** de cela n'existe : les 17 `module.json` ne portent que
`{name, version, type, description, requires}` (+ `mandatory`, `proposable`). `grep skills-only` et
`grep unsupported` sur le repo → 0 hit. Le champ `type` est un **faux ami** : prose libre non
validée, 12 formes distinctes pour 17 modules.

**Why:** le cadrage de la Phase 37 posait comme question « où vit la déclaration de capacité —
`module.json` avec un enum `full`/`skills-only`/`unsupported` ? ». La mesure montre qu'un tel enum
**ré-agrégerait à la main, en trois valeurs, ce que `degradationFor` calcule déjà par point
d'interface** — soit exactement la réimplémentation que la doctrine de la phase interdit
(« VibeFlow consomme la surface multi-runtime de gsd-core, il ne la réimplémente pas »). La
question était mal posée, et seule la mesure l'a révélé.

**How to apply:** sur toute discussion de portabilité ou de capacité par cible, ne propose jamais
un enum maison à N valeurs sans avoir d'abord lu `host-integration.cjs`. Si une déclaration doit
vivre dans `module.json`, elle doit **dériver son vocabulaire des axes gsd-core**, pas en inventer
un parallèle. Voir [[artefacts-descriptifs-non-testes]] et
[[feedback_re-deriver-les-listes-d-une-revue]] — même famille : l'artefact descriptif qui décrit
une capacité que personne n'a vérifiée.
