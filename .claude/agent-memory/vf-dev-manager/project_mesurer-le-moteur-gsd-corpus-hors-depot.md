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

**Rechute confirmée le 2026-09-09** (moteur 1.13.0, cadrage Phase 39), et elle ajoute un quatrième
axe : **le critère doit être PUBLIÉ avec le chiffre, pas seulement connu de celui qui mesure.** Un
relevé « 7 conscients / 89 » a été gravé au ROADMAP en se réclamant du critère K2 (« sait résoudre
un scope », `--ws` compris) alors que c'était un K1 (le mot `workstream` présent). Sous K2 le même
corpus donne **9/89**. L'écart est nominatif dans les deux sens : `plan-review-convergence.md` et
`verify-work.md` **assignent `--ws` sans jamais écrire le mot** (faux négatifs de K1) ;
`health.md:84` et `pr-branch.md:408` ne comptent **que par de la prose** (faux positifs de K4).

Pire, la phrase qui en était tirée — « la couverture amont n'a pas bougé en cinq semaines » —
**comparait un K1 de 2026-09-09 à un K2 de 2026-08-04**. Elle était vraie par accident, sur des
ensembles qui avaient changé : sous K1, 5 → 7 ; sous K2, 7 → 9 ; sous K4, 7 → 7 **mais avec un
échange** de membres. Deux « 7 » qui ne désignent pas les mêmes fichiers.

Et un cinquième garde-fou, découvert au même endroit : **82 des 89 workflows passent par le SDK**.
Un comptage lexical sur ce corpus est donc un **plancher de risque**, jamais la vérité — un
workflow sans marqueur peut être scope-correct si sa résolution transite par l'outil. Le trou réel
était ailleurs : huit workflows du cœur de chaîne **interpolent `${GSD_WS}` sans jamais
l'assigner**, la propagation amont étant une convention de *prompt* et non un câblage.

**How to apply (complément)** : exiger que le rapport publie le **critère en toutes lettres** à
côté du chiffre, et refuser toute comparaison entre deux relevés dont les critères ne sont pas
écrits — même quand les nombres coïncident, surtout quand ils coïncident. Un « inchangé » entre
deux dates est une affirmation sur des **ensembles** : la faire trancher par `comm`, jamais par
l'égalité des cardinaux (cf. [[ecart-de-chiffre-comparer-les-ensembles]]).
