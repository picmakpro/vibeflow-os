# Phase 23 — Arbitrages humains du 2026-08-02

Tranchés par Samuel après la clôture de la première mission d'exécution, qui avait gelé les
fichiers de doctrine et remonté sept points (cf.
`.planning/missions/2026-08-02-phase-23-couplage-gsd.md` §« Ce qui remonte à l'humain »).

Les points 1 à 4 commandent la suite : la Lacune 3 (plan 23-03) ne peut pas être écrite sans
savoir ce qu'un `--auto` auto-approuve. Les points 5 à 7 (périmètre des gates) restent ouverts et
seront instruits une fois les fichiers de doctrine réécrits.

---

## A-1 — RETRANCHÉ le 2026-08-02 : voir A-1bis

> ⚠️ **La décision ci-dessous est ANNULÉE.** Sa prémisse était fausse. Elle est conservée telle
> quelle pour la traçabilité ; la décision qui fait autorité est **A-1bis**, plus bas.

## A-1 (ANNULÉE) — D-02 inerte : retirer `--auto`, passer à `--assumptions`

**Décision.** `vf-coder` n'invoque plus le cadrage en mode `--auto`. Il utilise `--assumptions`.

**Pourquoi cette option plutôt que les deux autres.** On traite la cause, pas le symptôme : sans
`--auto`, plus rien ne pose le chain flag, donc plus rien ne ré-arme `workflow._auto_chain_active`
après le désarmement du geste 5. Les deux alternatives (désarmement porté par `vf-coder` après son
cadrage, ou re-désarmement par le manager à chaque retour de worker) laissaient toutes deux une
fenêtre armée et coûtaient des lignes sur un agent à 244/250.

**Rappel du mécanisme constaté.** Amont, `chain.md:39-42` ré-arme le flag si le chain flag est
présent **et** `AUTO_MODE` faux. Le geste 5 met `AUTO_MODE` à faux → satisfait la précondition ;
puis `vf-coder.md:27` invoque le cadrage en `--auto` → le flag repart à `true` pour toute la
mission. `--auto` était là parce que `vf-coder` n'a pas `AskUserQuestion` et bloquerait sur un
prompt ; `--assumptions` rend le même service sans poser de chain flag.

**Conséquence sur le gate T25.** Le gate déclarait cette ligne **licite** et l'immortalisait en
fixture — il était anti-corrélé au risque qu'il annonce couvrir. La fixture doit être inversée :
`--auto` sur le cadrage devient une forme **interdite**, prouvée par mutation.

## A-1bis — D-02 : garder `--auto`, et `vf-coder` désarme juste après son cadrage

**Décision (2026-08-02, révision de A-1).** `vf-coder` **garde** `--auto` sur le cadrage, et
**désarme le flag d'enchaînement immédiatement après** l'appel qui l'arme.

**Pourquoi A-1 était infondée — trois faits vérifiés contre `gsd-core@1.9.0` installé.**

1. `--assumptions` route, via `skills/gsd-discuss-phase/SKILL.md:54-55`, vers
   `workflows/list-phase-assumptions.md`, qui se déclare lui-même en tête :
   « *This is ANALYSIS of what Claude thinks, not INTAKE of what user knows. **No file output** —
   purely conversational* », et porte une attente bloquante (`Wait for user response.` l. 126).
2. **Aucun `CONTEXT.md` n'est écrit** ⇒ `gsd-planner` planifierait à vide.
3. `vf-coder` n'ayant pas `AskUserQuestion`, il retombe **exactement** dans le mode d'échec que la
   présence de `--auto` servait à éviter — la justification de A-1 se retournait contre elle-même.

**La voie par la config ne sauve rien non plus.** Le vrai mode assumptions non interactif serait
`workflow.discuss_mode="assumptions"` (`config.cjs:259`, absent de tout `plugin/` — 0 hit), qui
route vers `workflows/discuss-phase-assumptions.md`. Ce workflow **produit** bien un `CONTEXT.md`
(« *Output is identical to discuss mode — same CONTEXT.md* ») mais il est **interactif** : il
appelle `AskUserQuestion`. Même blocage.

**Conclusion.** Sur 1.9.0 il n'existe **aucun drapeau** qui soit à la fois non interactif,
producteur de `CONTEXT.md`, et sans chain flag. A-1 exigeait les trois : la cause qu'elle
prétendait traiter est **inatteignable en l'état**.

**Pourquoi A-1bis plutôt que les deux autres voies.** Le coût en lignes tombe sur `vf-coder`
(88/250, large marge) au lieu de `vf-dev-manager` (**249/250**, une ligne de marge). Le désarmement
est **adjacent** à l'armement, donc local et vérifiable par un gate de proximité — là où un
re-désarmement par le manager à chaque retour laisse une fenêtre armée pendant toute la durée du
worker. La troisième voie (le manager porte le cadrage lui-même, il a `AskUserQuestion`) supprime
le problème à la racine mais constitue un **changement structurel du cycle**, hors périmètre du
plan 23-01 — à reverser au débat si la Lacune 5 (voie unique d'invocation, plan 23-05) le rouvre.

**Conséquence sur le gate.** Le commit `e2b1bfe` avait figé `--assumptions` comme la forme licite
et faisait rougir le retour à `--auto` — **même anti-corrélation que celle qu'A-1 diagnostiquait,
étiquette retournée**. À défaire : `--auto` sur le cadrage redevient licite, et c'est **l'absence
du désarmement adjacent** qui doit rougir.

## A-2 — `workflow.auto_advance` : désarmé, dans la forme retenue en A-1bis

**Décision.** Le second déclencheur de la règle 5 amont (`checkpoints.md:11`), absent de tout
`plugin/`, est désarmé lui aussi. La forme suit celle retenue en A-1.

**Contrainte.** Correctif mécanique mais il coûte des lignes sur `vf-dev-manager.md` (244/250,
ADR-029). Déporter vers `plugin/dev-orchestrator/references/` si la marge ne suffit pas.

## A-3 — Minimum de reprise : élargir au couple réponse humaine + tâches faites

**Décision.** Le contrat de reprise transporte désormais **la réponse humaine** et **la table des
tâches déjà exécutées**, en plus des sous-champs décrivant la question.

**Pourquoi.** Les 4 sous-champs actuels décrivent tous *la question*. Le manager redispatche « avec
l'attendu » — c'est-à-dire avec la question qu'on vient de reposer — donc le worker neuf retombe sur
le même checkpoint et rend `human_needed` : **ping-pong sur un gate `blocking-human`**. Élargir
aligne le contrat sur l'amont, qui exige `{user_response}` et la table des tâches faites.

**Ce que ça rouvre.** Le contrat interdisait explicitement la table des tâches faites (garde
anti-duplication ADR-030). Cette interdiction est **levée pour ce cas précis** : la règle
anti-duplication visait la recopie de doctrine, pas le transport d'état de reprise. Le distinguo
doit être écrit, sinon la garde repart en faux rouge.

**Conséquence sur T26.** L'assertion « ensemble clos = exactement les 4 noms de D-03 » doit être
recalibrée sur le nouvel ensemble, et rester discriminante par mutation (rename des noms → KO).

## A-4 — Gel vs question : le mode départage explicitement

**Décision.** En mode **autonome**, un gate `blocking-human` **gèle le nœud** et la mission poursuit
les branches indépendantes du DAG ; la question est consignée au rapport pour l'humain. En mode
**supervisé**, l'agent **pose la question** et attend.

**Pourquoi.** Les deux clauses consécutives du contrôle de flux se contredisaient, la seconde sans
qualificatif de mode — or en mode autonome l'utilisateur est par définition absent, et un agent peut
résoudre la tension dans le mauvais sens en répondant lui-même à une attente humaine (violation
directe d'ADR-031). Les deux règles uniformes étaient plus simples à gater mais toutes deux
coûteuses : « toujours geler » interrompt les sessions supervisées où l'humain est disponible,
« toujours poser » arrête une mission de nuit au premier gate au lieu d'avancer sur les branches
libres.

**Exigence de gate.** La clause doit porter un **qualificatif de mode explicite** sur chacune des
deux branches — c'est précisément l'absence de ce qualificatif qui a créé la tension. Le gate doit
rougir sur une clause de contrôle de flux sans qualificatif de mode.

---

## Restent ouverts (périmètre des gates, non bloquants)

5. **`rc=3` contraint la forme rédactionnelle** — une réécriture en prose sémantiquement correcte du
   bloc Verdict rougit. À réinstruire **après** la réécriture commandée par A-1..A-4, puisque ce sont
   ces réécritures qui subiront la contrainte.
6. **Porosité de T25** — une prescription rédigée avec une négation dans la même clause échappe.
   Coût chiffré : ajouter `,` aux séparateurs ferme le trou et préserve les 6 fixtures, au prix d'un
   seul faux rouge (négation avec incise). Écart actuellement orienté vers le **faux vert**.
7. **Déclassement de T26 A′** — « aucun champ inventé côté worker » jugé non gateable par le worker,
   trop large par le reviewer. Piste retenue : gater sur les **positions de clé JSON**, couplé à un
   garde « ≥1 clé mesurée ou renvoi explicite ».
