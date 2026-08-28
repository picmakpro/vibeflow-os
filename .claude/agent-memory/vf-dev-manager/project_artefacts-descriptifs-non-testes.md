---
name: artefacts-descriptifs-non-testes
description: Sur ce repo, les défauts d'une phase se logent dans les artefacts qui DÉCRIVENT le code (recettes de plan, sondes grep, en-têtes de fichiers) — jamais dans le code ; aucun test ne les lit, et ils se propagent d'un document à l'autre
metadata:
  type: project
---

Dans une mission GSD sur `vibeflow-os`, le code livré tient (tests verts, revues PASS). Ce qui
casse, ce sont les **artefacts descriptifs** : lignes « Comment on vérifie » des `*-PLAN.md`,
sondes `grep` discriminantes, en-têtes de commentaires, docs `.planning/codebase/`. Aucune suite
de tests ne les lit, donc rien ne les contredit jamais.

**Why:** Phase 11 (migration GSD, 2026-07-26), 16 nœuds. **Trois vagues sur cinq se sont arrêtées
sur une contradiction de leur propre plan**, aucune sur une difficulté technique :
1. 11-01 — recette `grep -c 'get-shit-done-cc' ensure-deps.sh → 0` contre un `must_have` du même
   plan exigeant d'AFFICHER `npm uninstall -g get-shit-done-cc` (ADR-031). Appliquée telle quelle,
   elle détruisait le runbook de migration, c.-à-d. la raison d'être de la phase.
2. 11-02 — sonde `grep -c '\.claude/gsd-core/bin/gsd-tools\.cjs"' → ≥ 2` **inapplicable** : le 3e
   candidat s'écrit `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/..."` et l'accolade fermante
   casse la contiguïté du motif. Le code amont verbatim était correct, la sonde était fausse.
3. 11-04 — le correctif littéral du plan et le `must_have` « `test-merge-hooks.sh` reste vert »
   étaient **mutuellement exclusifs** (T2 encodait l'ancien comportement comme désirable).

Propagation observée : l'en-tête périmé de `detect-gsd-engine.sh:13` (`GSD_HOME` défaut legacy,
alors que le code fait une cascade `gsd-core` prioritaire) a servi de **justification** à un worker
pour laisser une mention obsolète dans `.planning/codebase/STACK.md`. Une doc fausse en contamine
une autre, en la citant comme preuve.

**How to apply:** (a) armer chaque mandat d'exécution de l'avertissement « si une recette contredit
un comportement que tu as prouvé correct, c'est probablement la recette qui a tort — remonte, ne
casse pas le code pour faire passer un grep » ; (b) **tester toute sonde avant de l'inscrire** dans
un plan (je me suis fait prendre à écrire un correctif de sonde sans l'exécuter d'abord) ; (c) quand
un worker rend `ask-user`, vérifier d'abord **lequel du plan ou du code ment** — sur 4 findings
`ask-user` de la Phase 11, **zéro** relevait réellement de l'humain (3 sondes fausses + 1 lacune de
vérification levée en une commande) ; (d) prévoir en fin de mission un nœud d'hygiène pour les
descriptifs rendus faux par la phase (en-têtes, `INSTALL.md`, `codebase/*.md`) — ils sont
« préexistants » mais la phase vient de les rendre mensongers. Voir
[[revue-obligatoire-cout-erreur-asymetrique]] et [[verifier-contre-le-commit-de-base]].

**Extension confirmée (étude Phase 18, 2026-07-28) — le JUGE aussi produit des artefacts non
testés.** Une contre-expertise a listé 19 défauts « mécaniques » avec numéros de ligne ; le
correcteur en a refusé 3, mesure à l'appui, et un arbitrage indépendant lui a donné raison **3 fois
sur 3** (le juge citait `check-doc-drift.sh` l. 5-7 pour 4-6, affirmait l'absence de Given/When/Then
là où `grep` en trouve 9, comptait 8 occurrences de `gsd-ship` pour 9). Un rapport de revue est
lui-même un descriptif que rien ne teste. **How to apply :** armer tout mandat de comblement de la
consigne « si un correctif demandé contredit un fait que tu peux prouver, ne casse pas le fait pour
satisfaire la consigne — refuse et donne la mesure », et arbitrer les refus par la commande, jamais
par l'autorité du juge.
