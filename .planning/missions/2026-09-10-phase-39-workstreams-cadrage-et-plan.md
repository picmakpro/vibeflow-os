# Mission — Phase 39 « Workstreams », cadrage et plan

**Dates** : 2026-09-09 → 2026-09-10 · **Branche** : `feat/phase-39-workstreams` · **Base** : `17b2c6f`
**Périmètre** : aller jusqu'au plan, puis STOP. L'exécution reste gatée par validation humaine (ADR-031).
**Résultat** : cadrage et plan livrés, 8/8 nœuds du DAG clos, **aucune exécution lancée**.

---

## 1. Plan de bataille (DAG `.planning/MISSION-39.dag.json`)

Quatre mesures parallèles sur périmètres disjoints → arbitrages humains → cadrage → plan → re-validation.
Deux `reopen` sur le nœud `plan` (deux tours de correction ciblée), jamais un cycle complet.

## 2. Ce qui a été mesuré (recherche préalable, précondition du cadrage)

Artefact : `.planning/research/2026-09-09-phase-39-workstreams-mesures-de-cadrage.md` (commit `d4d9a8d`).
Dix relevés, tous par exécution ou lecture de code avec `fichier:ligne`, sur `@opengsd/gsd-core` **1.13.0**.

| Sujet | Résultat |
|---|---|
| Niveau 4 du pointeur | **existe et fonctionne** — héritage sans jamais franchir un pointeur existant, auto-nettoyage d'un pointeur périmé |
| Collision ADR-064 | **refermée** entre deux sessions Claude distinctes · **OUVERTE** dans une équipe (sous-agents héritent du `CLAUDE_CODE_SESSION_ID` du parent → pointeur unique, dernier `set` gagnant). Discriminant = **la clé de session, pas le worktree** |
| Surface `--ws` | drapeau **global**, toute sous-commande l'accepte ; mais 22 workflows touchent `GSD_WS` et **3 seulement le fabriquent** — la propagation amont est une **convention de prompt**, pas un câblage |
| Migration | **clé en main** (`workstream.create`, rollback transactionnel) — rien à fabriquer |
| Layout | `PROJECT.md` **jamais résolu** sous un workstream (défaut reproductible en 3 commandes) |
| Couverture amont | **9/89** au critère « résout un scope » (le « 7/89 » gravé était un comptage lexical) ; 43 chemins en dur ; l'amont **bouge** (3 correctifs fermés les 7-8 sept.) mais **ne distribue pas** |
| `pr-branch` | le silence est levé au niveau **chemin**, il **subsiste au niveau COMMIT** — le risque (b) a **migré**, pas disparu |
| Split-brain | reproduit, `git merge-tree` **et** `git merge` en exit 0 ; signature robuste = **S2 + S4 + S5** |
| Gardes VF | **aucune** ne couvre la signature ; deux rendent « conforme » sur un dépôt divergé |
| Espace de noms | **40** préfixes au ledger (pas 42), **41 familles** réelles — `SIG-01..06` vit hors des deux ledgers |

**Trois chiffres gravés au ROADMAP ont été démentis et corrigés** (commit `20df9ab`) : les 42 préfixes,
le « 7/89 inchangé », et le « silence levé » de `pr-branch`. Sans cette correction, le cadrage aurait
planifié contre des prémisses fausses.

## 3. Arbitrages humains — six, tous par AskUserQuestion, aucun inféré

| # | Objet | Décision |
|---|---|---|
| 1 | Paradoxe d'auto-application | **A′** : preuve sur clone jetable, arbre de travail jamais partitionné, ADR-069 **non révisée**, aucun dépôt tiers. Partition réelle = geste post-clôture gaté humain |
| 2 | `GSDA-19` | **re-rédigée en bug de comportement** sur le défaut `PROJECT.md`. Rédigée, **jamais postée** |
| 3 | Compensation VF | **minimale** (`--ws` sur nos propres appels), aucun workflow amont réécrit, **veille datée sur événement** |
| 4 | Préfixe d'exigences | **`PART`**, pas `WSTR` (voisinage visuel avec `WKTR`/`WTCH`) |
| 5 | Critère 3 | **TOUS** les agents, sans exception — jamais « au moins un » |
| 6 | C17 — filet muet ? | **armé en CI**, mutité **non** assumée. Provenance vérifiée avant inscription |

Consignés dans `.planning/STATE.md` § `### Decisions` (commits `ca5fece`, `f26cb08`, `90a877c`).

## 4. Contrôle de flux — ce que la re-vérification a coûté et rapporté

**Le fait marquant de cette mission** : le `gsd-plan-checker` lancé **par l'agent qui venait d'écrire
les plans** a rendu « PASSED, 0 blocker ». Relancé **en contexte neuf**, sur les mêmes fichiers au
même commit, il a rendu **5 bloquants et 6 warnings**. Un second juge indépendant a confirmé les
mêmes défauts par d'autres chemins de mesure.

Les bloquants n'étaient pas des jugements de goût : c'étaient des **spécifications écrites contre une
arborescence imaginaire** — une clé d'extraction qui ne matchait **aucun** des 10 dossiers de phase,
un signal de cardinalité qui rougissait sur un arbre **sain**, une fixture qui commitait des dossiers
**vides** que git ne versionne pas.

**Cinq tours** — les quatrième et cinquième demandés par Samuel le 2026-09-10 (AskUserQuestion, session
principale) sur la foi de la réserve n°2 de ce rapport :
1. Plans initiaux → 5 bloquants + 6 warnings (2 juges frais, findings fusionnés, **un seul** `reopen`)
2. Correction C1→C17 → rejeu **par exécution** : 5 points tiennent, 3 prises restent, dont **une neuve**
3. Correction D1→D5 → preuves des **deux** directions (vert nominal **et** rouge fautif)
4. **4ᵉ passe, juge frais et exécutant** → tout tient **sauf un bloquant** : la preuve d'observance de
   `--ws` était **structurellement vide pour un worker sur deux**. Racine mesurée dans le moteur :
   `workstream.cjs:186` — `workstream.create <nom>` fait du nouveau compartiment l'**ambient
   default**, donc « sans drapeau » et « `--ws <ce compartiment>` » rendent la **même sortie à
   l'octet près**. Corrigé en séparant les trois sorties (peupler la cible **et** créer un
   compartiment poubelle en dernier — mesuré : ni l'un ni l'autre ne suffit seul), et en faisant
   remonter la preuve à deux workers dans le bloc **machine** au lieu de la prose.

5. **5ᵉ passe, ciblée et exécutante** (demandée par Samuel le 2026-09-10, avec règle d'arrêt posée
   d'avance) → **ZÉRO BLOQUANT**. Le correctif du 4ᵉ tour est confirmé de bout en bout par des
   mesures indépendantes : trois empreintes mutuellement distinctes, contrôleur **rouge sur
   l'omission de chacun des deux workers**, jeton machine qui **peut** valoir 0, et les deux volets
   prouvés **chacun insuffisant seul, suffisants combinés**. Restent un **majeur** (deux critères
   d'acceptation de `39-03` T1 mesurés faux — voir réserve 6) et un **mineur** (l'explication du plan
   se trompe de mécanisme, sa conclusion reste juste).

**Le motif de la mission** : les trois défauts bloquants successifs sont le **même** — un mécanisme
qui a l'air correct et **ne peut pas rendre rouge**. Une clé d'extraction qui ne matche rien, un shim
de `PATH` qui ne capture rien, une empreinte indiscernable. Chaque correctif était une vraie
amélioration ; l'inertie se déplaçait d'un cran au lieu de disparaître. **Tous les trois sont
invisibles à la relecture et évidents à l'exécution** — c'est l'argument le plus net de cette mission
en faveur des juges exécutants.

## 5. Livrables

- `.planning/phases/VFDO-39-…/` : `39-CONTEXT.md`, `39-DISCUSSION-LOG.md`, `39-PATTERNS.md`,
  `39-01-PLAN.md` (filet S2+S4+S5, hook + **câblage CI**, mutation rouge),
  `39-02-PLAN.md` (famille `PART-01..09`, `GSDA-19` superseded, amendement daté ADR-069, gabarit de dispatch),
  `39-03-PLAN.md` (preuve sur clone jetable, `--ws` exhaustif par l'effet, déclencheur de reprise)
- `.planning/research/2026-09-09-phase-39-workstreams-mesures-de-cadrage.md`
- `.planning/BACKLOG.md` : proposition **non installée** de convention de traçabilité des arbitrages

**Estimates** (verbatim, aucun `actuals` — rien n'a été exécuté) :
`39-01: {tokens: 46000, tasks: 2}` · `39-02: {tokens: 50000, tasks: 3}` · `39-03: {tokens: 42000, tasks: 2}`
(comptes de tâches antérieurs aux corrections ; `39-01` en porte 3 et `39-02` en porte 4 depuis).
`verdicts` : absent — aucun `gsd-execute-phase` invoqué.

## 6. Réserves portées au rapport

1. **Le ledger ne porte pas encore `PART-xx`** — la gravure dans `REQUIREMENTS.md` est un livrable de
   `39-02` T1, non exécuté. Le libellé du ROADMAP a été reformulé pour ne pas le laisser croire.
2. **Les preuves du 4ᵉ tour sont déclarées par le correcteur** — avec empreintes md5 des deux
   directions pour les deux workers, et un jeton machine désormais câblé dans le bloc `<automated>`
   (vérifié : troisième condition du test) — mais **sans 5ᵉ passe de juge frais**. Samuel avait
   demandé la 4ᵉ et posé la règle « s'il trouve des bloquants, corrige puis reviens ». C'est fait ;
   la décision d'une 5ᵉ passe lui revient.
3. **`vf-dev-manager.md` est à 250 lignes pile** — plafond ADR-029 au ras, et `check-agents.sh` ne
   compte pas les lignes. Le plan porte sa propre garde `wc -l ≤ 250`.
4. **Dette d'outillage constatée** (backlog) : le watchdog a signalé deux fois un « stall » sur la
   cadence des transitions de DAG alors qu'un worker travaillait 20 minutes d'affilée — faux positif
   structurel de la mission longue. Et `gsd-planner` est absent de l'allowlist déclarée de `vf-coder`
   mais accepté à l'exécution.
5. **`rtk`** : les pièges **établis** (sortie vide rendue comme 1 ligne, `grep` piped qui tronque,
   `ls` rendant vide un dossier peuplé) ont joué. Un juge a **rapporté** en plus un `cat` tronquant un
   fichier long et un `sed -n` servant `HEAD` au lieu du disque — **non reproduits** depuis
   (`rtk cat` sur un fichier de 497 lignes n'a pas tronqué) : à traiter comme **rapporté, pas
   établi**. Le réflexe de recouper toute conclusion importante par une seconde méthode reste bon
   indépendamment de la cause.

6. **Deux critères d'acceptation de `39-03` T1 sont mesurés FAUX** sur la séquence exacte qu'il
   prescrit, sans `GSD_WORKSTREAM` exporté (ce que le plan interdit) :
   `check-workstream-pointer.sh --path <clone>` rend **exit 1** (le critère attend 0) et
   `check-state-integrity.sh --path <clone>` rend **exit 2** (l'action attend 0). Cause **structurelle
   sous Claude Code** : une clé de session résout toujours, donc le marqueur partagé n'est jamais
   écrit, et la garde refuse explicitement le pointeur de session comme canal composable. Avec
   `GSD_WORKSTREAM=legacy` **inline**, les deux passent à 0. Aucun des plans ne modifie ces scripts.
   **Non-régression sur le dépôt réel intacte** (pointer → 3, state-integrity → 0).
   *Classé `majeur`, pas bloquant, par le juge — donc non corrigé, conformément à la règle d'arrêt.*
7. **Incohérence interne mineure de `39-03` T1** : le bloc `<automated>` lance le gate de divergence
   **avant** `sink` + peuplement, alors que l'`<action>` prescrit de le lancer **après** les workers.
   La preuve machine et le critère d'acceptation n'exercent pas le même état.
