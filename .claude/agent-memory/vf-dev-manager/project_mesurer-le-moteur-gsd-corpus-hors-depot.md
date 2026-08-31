---
name: mesurer-le-moteur-gsd-corpus-hors-depot
description: Tout comptage sur les workflows du moteur GSD porte sur ~/.claude/gsd-core/, hors dépôt — non épinglable à un commit ; la seule ancre est le fichier VERSION
metadata:
  type: project
---

Les workflows du moteur GSD vivent dans `$HOME/.claude/gsd-core/workflows/`, **hors du dépôt**.
`git ls-tree -r --name-only <sha> -- gsd-core/workflows` rend **0 fichier** : aucun comptage
portant sur le moteur ne peut être épinglé à un commit du lab. La seule ancre de reproductibilité
est `~/.claude/gsd-core/VERSION` (lecture directe du fichier — `node
~/.claude/gsd-core/bin/gsd-tools.cjs --version` **exit 1**, ce n'est pas une source utilisable).

Deux axes font diverger deux comptages de bonne foi sur ce corpus, et il faut nommer les DEUX :
- **La profondeur** : `workflows/*.md` = **91** fichiers ; en récursif = **115** (les extra vivent
  sous `help/modes/`). Un « en récursif » non dit décale tous les chiffres.
- **Le motif** : un motif étroit et intentionnel ne se compare pas à un motif large. Exemple gravé
  par ADR-069 : « fichiers codant `.planning/` en dur » = **45** avec le motif
  `.planning/(ROADMAP.md|STATE.md|phases)` — les seuls trois artefacts que la partition en
  workstreams déplace (critère écrit en clair dans
  `plugin/dev-orchestrator/references/workstreams.md:101`). Toute occurrence de `.planning/` en
  récursif donne **73**, dont 25 chemins que la partition ne déplace pas (`config.json`, `debug/`,
  `codebase/`, `seeds/`…). 45 ⊂ 70, vérifié par `comm -23` vide.

**Why:** ce dépôt a un fil rouge documenté — « un décompte juste portant sur le mauvais ensemble »
— à sa 5ᵉ occurrence en Phase 27. La re-dérivation du 2026-08-05 (moteur 1.9.1) a confirmé
**ADR-069 sur ses deux comptages** (`workstream` K2 = **7/91**, `.planning/` en dur = **45**,
42 aveugles) : ce n'est pas ADR-069 qui avait dérivé, c'est la recherche de cadrage, dont le motif
`--ws ` (espace littéral) ne matchait **rien** et dont le K2 s'était silencieusement effondré en K1.

**How to apply:** avant de commander ou d'accepter un comptage sur le moteur, exiger dans le
rapport la **profondeur**, le **motif** et la **version du moteur** — sans les trois, le chiffre
n'est pas comparable à un chiffre gravé. Ne jamais demander d'épingler sur un commit du lab une
mesure du moteur : le mandat serait impossible à tenir. Et ne jamais laisser écrire « fichiers
codant `.planning/` en dur » sans dire **quels chemins** — c'est cette ellipse qui a produit
l'écart. Voir [[verifier-contre-le-commit-de-base]] pour le cas symétrique (mesure DANS le dépôt,
elle épinglable) et [[re-deriver-les-listes-d-une-revue]].
