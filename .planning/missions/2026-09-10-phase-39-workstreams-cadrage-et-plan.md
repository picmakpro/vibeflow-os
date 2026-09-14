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


---

# PARTIE II — EXÉCUTION (2026-09-10)

Feu vert d'exécution rendu par Samuel (AskUserQuestion, session principale, 2026-09-10), après
correction préalable des deux réserves de la 5ᵉ passe. **33 commits** sur `feat/phase-39-workstreams`.

## Déroulé

| Vague | Contenu | Juges |
|---|---|---|
| Correction pré-exécution | 4 points de `39-03` T1 (gardes préfixées, mécanisme, attribution de preuve, ordre du bloc machine) | — |
| **Vague 1**, deux exécutants **parallèles** sur périmètres disjoints | `39-01` filet + hook + CI · `39-02` ledger + ADR + doctrine | **3** : revue ×2 + **audit infra** |
| Correction fusionnée | 2 bloquants + 4 majeurs + 1 mineur, **un seul reopen** | — |
| **Vague 2** | `39-03` preuve sur clone jetable + déclencheurs | revue ×1 |
| Compléments | `39-01-SUMMARY` manquant · ancrage D-02 · hygiène documentaire | — |

## Ce qui a été livré

- **Filet de détection de divergence** : `check-divergence.sh` (S2+S4a+S4b+S5), suite de **10 cas dont
  2 mutants**, hook `post-merge` **opt-in**, étape CI avec **bascule de mutation prouvée**.
- **Famille `PART-01`→`PART-09`** gravée, `GSDA-19` **superseded** (identifiant neuf, statut d'origine
  intact), **amendement daté** d'ADR-069, doctrine `workstreams.md` §4 étendue, gabarit de dispatch
  du manager amendé (chaque worker reçoit `--ws`, jamais par héritage).
- **Preuve d'adoption** sur clone jetable : trois empreintes mutuellement distinctes, deux workers
  concurrents, gates verts dans le clone partitionné et **non-régression** sur l'arbre réel.
- **Issue amont rédigée, jamais postée.** **Arbre de travail jamais partitionné.**

## Les sept occurrences du même défaut

Le fil rouge de cette phase, du cadrage à l'exécution : **un mécanisme qui a l'air correct et ne peut
pas rendre rouge**. Tous invisibles à la relecture, tous trouvés par exécution.

1. Clé d'extraction ne matchant **aucun** dossier de phase du dépôt.
2. Signal de cardinalité rougissant sur un arbre **sain** (convention d'archivage).
3. Fixture commitant des dossiers **vides** — git ne les versionne pas, le merge devient un no-op.
4. Shim de `PATH` incapable de capturer (l'environnement ne survit pas d'un appel Bash au suivant).
5. Empreinte **indiscernable** de son témoin (`workstream.create` fait du compartiment créé le défaut ambiant).
6. **Mutant échouant pour la mauvaise raison** — dépendance sœur absente, `rc=2` accepté par une
   assertion trop permissive. *Le manager avait lui-même validé ce vert.*
7. **Le gate lui-même** rendant « conforme » sur un dépôt divergé si `mktemp` échoue (pas de `set -e`).

## Sécurité — une RCE démontrée, pas soupçonnée

L'audit infra a trouvé que le hook neuf dupliquait un candidat RCE déjà catalogué. En le mitigeant,
le correcteur l'a **démontré** : worktree hostile, copie malveillante, **vrai `git merge`** → exécution
de la copie hostile, fichier témoin créé. Hook corrigé, même scénario → plus rien.

**Arbitrage Samuel (AskUserQuestion, session principale, 2026-09-10)** : mitiger le hook **neuf**
seulement, `pre-push` non touché — « assumer une dette héritée et l'écrire à neuf ne sont pas le même
geste ». Le mécanisme prescrit (résoudre depuis l'emplacement du hook) s'est révélé **insuffisant à la
mesure** — sous `core.hooksPath` relatif, git résout aussi le hook depuis le worktree courant ; le
correcteur a ancré sur le dépôt principal. **Intention tenue, moyen substitué — signalé.**
Finding consolidé dans `.planning/codebase/CONCERNS.md` : **ouvert** sur `pre-push`, **mitigé** sur
`post-merge`. Pas d'issue publique (écarté à l'arbitrage).

## État final vérifié par le manager

`check-agents` **0** · invariants **3 (SAIN)** · suite divergence **10/10** · `check-state-integrity`
**0** · `check-divergence --path .` **3** (silence, dépôt non partitionné) · `.planning/workstreams/`
**absent** · arbre **propre** · `vf-dev-manager.md` **250/250** lignes.

## Réserves à la clôture

1. **Le diff de correction post-revue n'a pas été vu par un juge indépendant.** Il inclut la
   **mitigation de sécurité**. Le manager l'a vérifié **par exécution** (suite 10/10 avec mutant
   devenu opposable, garde `mktemp` rendant 2, hook ancré, `pre-push` intact), mais aucun regard frais
   n'a jugé ce diff. C'est la seule vérification manquante.
2. **Aucun run CI réel observé** — l'étape a été prouvée localement, rien n'a été poussé.
3. **`CHANGELOG` du module `conductor` sans entrée** : sa convention lie une entrée à un bump de
   version, or le bump est un geste de release. À faire **au moment du ship**.
4. **Cochage des exigences différé** : `PART-01..09` restent `[ ]` au ledger, cohérent avec le patron
   de phase du dépôt, à traiter à la clôture.
5. **Preuve de mécanisme ≠ preuve d'usage** : le clone établit que le mécanisme marche, pas qu'un
   usage concurrent réel tient. Écrit tel quel dans les livrables.


---

# PARTIE III — ÉTAT DE REPRISE (2026-09-14)

> **Écrit pour quelqu'un qui reprendra ce dossier sans le contexte de la session d'origine.**

## Où en est-on exactement

La Phase 39 est **exécutée, revue, corrigée et vérifiée**. **41 commits locaux** sur la branche
`feat/phase-39-workstreams`, **rien n'est poussé**, aucune PR, aucun bump de `VERSION`, aucun tag.

**Le ship n'attend aucun travail technique de cette phase.** Il attend un **hotfix produit par une
session parallèle**, que Samuel a décidé d'intégrer à la **même release** (arbitrage Samuel,
AskUserQuestion session principale, 2026-09-14). C'est un choix de **groupage de release**, pas un
report technique.

## Gates au moment de la mise en attente — tous verts, valeurs mesurées

| Gate | Valeur | Sens |
|---|---|---|
| `bash scripts/check-version-sync.sh` | **0** | 77 suites réelles = 77 annoncées dans les deux README |
| `plugin/conductor/scripts/check-agents.sh` | **0** | agents conformes |
| `plugin/conductor/scripts/check-mission-invariants.sh` | **3** | SAIN (3 est le seul « vérifié conforme ») |
| `plugin/conductor/scripts/tests/test-check-divergence.sh` | **0** | **17/17**, mutants inclus |
| `plugin/conductor/scripts/check-state-integrity.sh` | **0** | conforme |
| `plugin/conductor/scripts/check-divergence.sh --path .` | **3** | silence — dépôt **non partitionné**, attendu |
| `.planning/workstreams/` | **absent** | arbre de travail jamais partitionné (arbitrage A′) |
| arbre de travail | **propre** | aucun fichier suivi modifié |
| driver-lock | **relâché** | `{"present": false}` |

## Les deux réserves connues, inchangées

1. **Aucun run CI distant n'a été observé.** L'étape CI a été prouvée **localement** (extraite du YAML
   et rejouée, verte sur le script réel, rouge contre un mutant). La CI ne se prononcera qu'à la
   première poussée.
2. **Le clone jetable prouve un MÉCANISME, pas un usage concurrent réel.** Ce dépôt n'est pas
   partitionné et sa partition réelle reste un geste humain postérieur (déclencheur D-02, inscrit dans
   `.planning/STATE.md` § Decisions et rappelé au point de dispatch dans `mission-flow.md`).

## CHECKLIST DE REPRISE — trois pièges à l'intégration du hotfix

1. **Le compteur de suites se rouvre en silence.** `check-version-sync.sh` compare le nombre réel de
   `*/tests/test-*.sh` aux deux README. **Si le hotfix ajoute ou retire une suite, le gate redevient
   rouge** — c'est exactement le bloquant fermé le 2026-09-14, et il ne s'annonce pas. **Re-dériver le
   compte soi-même** après intégration (en Python ou `find`+`awk`, jamais un `grep` piped qui tronque)
   — ne jamais reprendre le chiffre d'un rapport antérieur, celui-ci compris.
2. **Rejouer TOUS les gates après intégration**, pas seulement ceux que le diff du hotfix semble
   toucher. Un vert mesuré **avant** fusion ne dit rien de l'après.
3. **Vérifier le driver-lock avant tout checkout dans l'arbre principal** :
   `plugin/conductor/scripts/driver-lock.sh status`. Une autre session écrivait dans ce dépôt au
   moment de la mise en attente. Si le lock est tenu par un tiers → **worktree**, jamais un checkout
   dans l'arbre principal. Ne pas supposer que l'arbre est à soi parce qu'il l'était une heure plus tôt.

## Ce qui reste fermé, quoi qu'il arrive

- **Aucun `/gsd-ship`** sans geste humain explicite — à chaque fois, sans exception.
- **Aucune partition réelle de `vibeflow-os`** : geste séparé, gaté humain, postérieur à la clôture.
- **Aucun dépôt de l'issue `GSDA-19`** chez OpenGSD : elle est **rédigée** dans
  `.planning/upstream/2026-09-09-init-progress-project-md-not-resolved-under-workstream.md`, Samuel
  poste.
- **Ne pas « réparer » le résiduel de sécurité en basculant `core.hooksPath` sur un chemin absolu** —
  la mesure et son raisonnement sont dans `.planning/codebase/CONCERNS.md`.

## Hors périmètre, signalé et non traité

`plugin/validator/README.md` annonce **249 lignes** pour un fichier d'agent introuvable au chemin
attendu. Dérive d'un autre module, antérieure à cette phase.

## Au moment du ship, deux dettes se règlent d'elles-mêmes

- L'entrée de `plugin/conductor/CHANGELOG.md` : sa convention lie une entrée à un **bump de version**.
- La ligne d'historique des deux README racine, indexée sur le `VERSION` taggé.
