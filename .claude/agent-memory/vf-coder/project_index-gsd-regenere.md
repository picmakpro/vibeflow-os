---
name: index-gsd-regenere-a-l-install
description: gsd-skills-index.md versionné est régénéré in-place par l'installeur — toute assertion de couverture écrite contre lui est une cible mouvante
metadata:
  type: project
---

`plugin/dev-orchestrator/references/gsd-skills-index.md` est **auto-généré** (`build-gsd-index.sh`)
et **régénéré in-place par l'installeur à chaque install** (`plugin/_internal/vibeflow-update.sh`,
autour de la l. 527). La copie versionnée est donc une **photo datée**, pas une référence stable :
au 2026-07-25 elle listait 65 skills (générée le 2026-06-04) alors que le poste en avait 67
(`gsd-mvp-phase` et `gsd-surface` manquants).

**Why:** tout test ou document qui affirme « 100 % de couverture de l'index » passe en local et
casse au premier `update` d'un lab, puisque l'index grossit tout seul. Rencontré en écrivant
`references/intent-routing.md` (étape 12, VERB-05).

**How to apply:** écrire la doctrine contre le **sur-ensemble** (index versionné ∪ `~/.claude/skills/gsd-*`),
et formuler les tests d'exhaustivité **contre l'index lui-même**, jamais contre un nombre figé.
Ne jamais éditer l'index à la main pour faire tomber une couverture juste — c'est la doctrine qui
s'aligne sur l'index. Attention aussi aux faux positifs d'extraction de tokens : `gsd-index`
(issu de `build-gsd-index.sh`) et `gsd-sdk` ne sont pas des skills — comparer sur les lignes
`| gsd-… |` du tableau.

Voir aussi [[check-agents-scope]].
