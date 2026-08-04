# Mission — Phase 24 : activation et mesure du moteur GSD

**Date d'ouverture :** 2026-08-04
**Manager :** `vf-dev-manager` (dispatché en sous-agent)
**Périmètre :** Phase 24 du jalon `gsd-migration` — cycle complet cadrage → plan → exécution →
vérification. **Frontière stricte : la Phase 25 est hors périmètre** (la ROADMAP la documente
explicitement comme distincte).
**Plan de bataille :** `.planning/missions/dag-phase24.json`

---

## Gestes d'ouverture (protocole ADR-053)

| Geste | Résultat |
|---|---|
| Résolution `$S` | `plugin/conductor/scripts` (repo source — PRIME sur `~/.claude/scripts`) |
| Verrou de driver | `acquired: true`, `owner=mission-phase24`, `recovered: false` — aucune mission concurrente |
| Gate d'invariants | `check-mission-invariants.sh` → **SAIN** (exit 0), aucune zone morte |
| Reset des flags d'enchaînement | `gsd_run` **ABSENT** de l'environnement → geste best-effort échoué. **Vérifié directement dans `.planning/config.json` : `workflow._auto_chain_active: false` ET `workflow.auto_advance: false` déjà tous deux à `false`.** Aucun déclencheur d'auto-approbation armé. |
| Base de mission | `08a563d` (`main`, arbre propre hors artefacts de mission) |

---

## Plan de bataille

Étapes modélisées en DAG. La Phase 24 est un **inventaire d'audit** (11 items : M1, M2, M3 +
A1→A9), pas une feature — chaque item est une **décision**, pas un travail évident. D'où un nœud
de constat dédié en amont du plan, plutôt qu'un cycle `vf-coder` déroulé tout droit.

| Nœud | Rôle | Dépendances | État |
|---|---|---|---|
| `facts` | constat sur pièce des 11 items + fiche d'arbitrage groupée par zone | — | **done** |
| `research-web` | 3 points non refermables sans accès web | — (parallèle) | running |
| `checkpoint-arbitrages` | arbitrage humain, 6 questions fermées | `facts` | **bloqué — human_needed** |
| `plan` | plan de phase (`gsd-plan-phase`) | `checkpoint-arbitrages` | blocked |
| `plancheck` | re-validation des plans avant exécution | `plan` | blocked |

Les nœuds d'exécution, de revue et le nœud `docs` unique de fin de mission seront posés **après**
l'arbitrage : leur découpage dépend directement des options retenues (une zone refusée ne produit
qu'un ADR, une zone activée produit une clé de config, un cas de test et un gate).

---

## Nœud `facts` — résultat

**Worker :** `vf-coder`, mandat de cadrage seul (arrêt avant le plan).
**Livrables** (commit `fbdb300`, 3 fichiers, pathspec explicite, parent = `08a563d` — aucun
travail concurrent mêlé) :

- `24-CONTEXT.md` (430 l., fiches de fait `F-01` à `F-38`)
- `24-ARBITRAGES.md` (291 l., 6 zones, 4 options chacune)
- `24-DISCUSSION-LOG.md` (202 l.)

### Le constat central : les faits du ROADMAP périment en jours, pas en mois

Les faits de la Phase 24 ont été établis le **2026-07-31** contre `gsd-core@1.9.0`. Re-vérifiés le
**2026-08-04** contre `gsd-core@1.9.1` et le dépôt en `v2.47.1` : **8 faits sur 23 ont péri en
4 jours, et 3 d'entre eux inversent la conclusion de leur item.**

C'est la justification rétrospective du nœud `facts` : planifier directement sur le ROADMAP aurait
produit un plan bâti sur trois prémisses fausses.

**Les trois inversions :**

1. **A4 — les profils de contexte n'ont aucun consommateur.** La clé `context:` est validée
   (`config.cjs:690-692`) et documentée, mais la recherche exhaustive sur tout `gsd-core`,
   `~/.claude/agents` et `~/.claude/skills` ne rend que **3 hits, tous auto-déclaratifs**. Le
   moteur *déclare* la capacité, il ne la *porte* pas. La prémisse du ROADMAP (« nous
   ré-implémentons en doctrine ce que le moteur porte en config ») est **fausse**.
2. **A5 — « le lab impose des commits conventionnels, un gate existe » est faux.** Aucun des 6
   `plugin/*/hooks/hooks.json` ne déclare de gate de message de commit ; c'est une **consigne** du
   `CLAUDE.md`, pas une garantie machine. Et la mesure qui tranche : sur **109 commits locaux**,
   **23 échouent sur le type** (6 types maison absents de la liste amont) et **69 % dépassent
   72 caractères**.
3. **A9 — la PR #27 est CLOSE** depuis le **2026-08-03T06:56:32Z**, jamais mergée. Le statu quo de
   fait est déjà le refus. Couverture workstream amont re-mesurée en `awk`+`comm` (jamais en `grep`
   piped, qui tronque) : **7/91 = 7,7 %**, pas 18 % — **45 workflows codent les chemins en dur,
   dont 42 sans aucune conscience des workstreams**.

**Plus :** A1 — `WINDOWS.md` porte `open_count: 1` (pas 2), et la fenêtre restante (#3, recette
XcodeBuildMCP) est **structurellement infermable dans ce dépôt** (aucun `.mcp.json`, aucun projet
iOS). Activer `windows_enforce` sans dérogation tuerait `/gsd-ship`.

### Trois faits nouveaux, invisibles depuis le ROADMAP

- **A2 — le levier « le plus fort de l'audit » est un candidat au vert-à-vide côté exécuteur.** Le
  slot `AGENT_SKILLS_EXECUTOR` n'est injecté que dans le prompt de dispatch d'`execute-phase.md`,
  or `gsd-executor` et `gsd-planner` ont été **retirés de l'allowlist de `vf-coder` en Phase 23**
  et le repli est l'inline séquentiel, **sans injection**. Le slot `PLANNER`, lui, est atteignable.
- **A3 — `tdd_mode` n'apporte presque rien.** `references/tdd.md` (330 l.) est **déjà injecté sans
  condition** (`execute-phase.md:693`) ; le toggle n'ajoute qu'un tag `type: tdd` et un gate
  `execute:post` **non bloquant** (`onError: skip`). L'heuristique amont est de surcroît calibrée
  pour des dépôts applicatifs — sur du bash et du markdown, elle classerait presque tout en
  `execute`.
- **A7 — une TROISIÈME route inerte, que le ROADMAP ne voit pas.** Notre propre `docs-flow.md:43-44`
  publie `--query` comme l'un des deux **modes normaux** de `gsd-map-codebase`, or ce mode exige
  `intel.enabled: true`. **C'est notre doc qui promet un geste mort.**
- **M3 — le barème `effort:` existe déjà.** 0 des 25 agents livrés en porte un, mais **3
  agents-templates** (`business-agent-template.md: medium`, `clarity-feature-template.md: high`,
  `orchestrator-template.md: high`) en portent déjà un. Ce n'est pas une doctrine à inventer, c'est
  une doctrine à **propager**.

### Écarts de protocole relevés par le worker

1. **`update_state` du workflow amont délibérément sauté** — il appelle `gsd-tools query
   state.record-session`, interdit par mandat (ADR-063 : réécriture de `STATE.md` avec
   `resync:true` non désactivable, régression silencieuse des compteurs `progress`). Baseline
   **intacte et vérifiée** : `total_phases: 26 / completed_phases: 23 / total_plans: 79 /
   completed_plans: 79`.
2. **`present_gray_areas` converti en fiche** — le skill de cadrage voulait un `AskUserQuestion` ;
   `vf-coder` n'a pas cet outil (worker cloisonné, comportement attendu). Les 6 zones ont été
   posées en questions fermées à options ≤ 12 mots, prêtes pour un unique passage cochable.

---

## Nœud `checkpoint-arbitrages` — BLOQUÉ, `human_needed`

**Cause : repli D-09.** `AskUserQuestion` figure dans le `tools:` déclaré de `vf-dev-manager`, mais
le runtime ne l'a **pas fourni** à cette instance dispatchée en sous-agent. Conformément à la
doctrine (sens fermeture), le manager ne force pas et **n'auto-répond pas en silence** : les
6 arbitrages remontent au dispatcheur, qui les pose à Samuel.

Les 6 questions, leurs options et les recommandations motivées sont dans
`24-ARBITRAGES.md`. Synthèse des recommandations du cadrage :

| Zone | Items | Recommandation |
|---|---|---|
| 1 — doctrine vers les agents du moteur | A2, A3 | **A** — slot `PLANNER` seul, sans `tdd_mode` |
| 2 — ce qui bloque vs ce qui signale | A1, A5 | **C** — `windows_enforce` (après dérogation #3) + `workflow_guard` ; `community` refusé |
| 3 — routes inertes | A7, A8 + une 3ᵉ | **A** — activer `intel`, refuser les deux autres, **ajouter le gate d'activation** |
| 4 — réglages ré-implémentés | A4, A6 | **A** — refuser les profils, ne pas toucher au seuil (mesuré : 4 plans sur 28) |
| 5 — workstreams | A9 | **D** — refuser, et remonter les 42 workflows aveugles en amont |
| 6 — faits de runtime par rôle | M1, M3 | **A** — écrire la marge de profondeur **et** `effort:` par rôle |

**Le vrai livrable de la zone 3 n'est aucune des activations** : c'est le **gate qui relie une
entrée de doc à l'activation de sa capability**. Il est absent aujourd'hui, il est identique dans
les options A et B, et sans lui le trou se rouvre au prochain skill ajouté — c'est exactement ce
que le ROADMAP relevait en A8 (« une couverture verte peut masquer un geste mort »).

---

## Nœud `research-web` — résultat (dispatché en parallèle de `facts`)

Les 3 points non refermables sans accès web sont refermés. **Deux d'entre eux amendent
matériellement la fiche d'arbitrage — les options ci-dessus ne se lisent plus sans eux.**

### 1. PR #27 — le refus est déjà ratifié par les deux parties, et le sujet a un rendez-vous

Fermée **par Willy (`picmakpro`) lui-même**, le 2026-08-03T06:56:32Z, sans merge. Ce n'est ni un
retrait spontané ni un refus imposé : **c'est un acquiescement de l'auteur à la revue de Samuel**
(« objection fondée, **et vérifiée de mon côté** »). Willy re-vérifie et retient les deux motifs
(pointeur indexé sur le `realpath` du `.planning` → incompatible ADR-064 ; couverture amont), et
ajoute une **preuve empirique de son propre usage** : une session en mode workstream a produit un
hook de démarrage repassé en « feuille de route absente », un `init.phase-op` en échec, et un
`state.record-session` qui a écrasé `total_phases` **trois fois**.

**Mais le besoin n'est pas clos** : « Le sujet n'est pas abandonné : @Samuel le prend en
**Phase 27**. Le diagnostic d'origine reste valable. » La branche
`gouvernance/partition-planning-workstreams` est **conservée** (122 renommages vérifiés, 210 blobs,
0 perdu). Aucun successeur sur GitHub (33 PRs, 1 issue, aucune sur le sujet).

> **Conséquence** — l'ADR de la zone 5 doit se rédiger comme un **refus contradictoire ratifié et
> daté (2026-08-03)**, formulé « refus d'adoption **en l'état, à taux de couverture amont donné** »,
> **jamais** « refus définitif du concept ». Et il doit nommer le rendez-vous Phase 27.
> ⚠️ **Cette Phase 27 n'existe pas dans `.planning/ROADMAP.md`** — l'inscrire est une **extension
> de périmètre**, donc une décision de Samuel, pas de la mission.

### 2. Broken windows — un bloquant dur que le cadrage ne pouvait pas voir

- **Aucun critère amont de bascule.** Le seul énoncé normatif est « *teams can adopt tracking
  before enforcement* » — une séquence, pas un critère. Aucun `docs/how-to/`, aucune issue.
  Activer `windows_enforce` est une **décision purement locale**.
- **La dérogation est officielle et auditable** : `gsd-tools windows waive <id> "<raison>"`, raison
  obligatoire (`broken-windows.cjs:80`), l'entrée passe `open` → `waived`, sort du `open_count`
  bloquant et **reste visible** dans `/gsd-progress`. Donc « la fenêtre #3 est infermable » n'est
  **pas** un motif de rester à `false` — le cadrage était trop prudent sur ce point.
- **⛔ MAIS — issue amont [#2893](https://github.com/open-gsd/gsd-core/issues/2893),
  `confirmed-bug` : `windows append` DÉTRUIT toute la prose sous le ledger JSON et rapporte
  `ok: true`.** Corrigée par PR #2975 mergée le **2026-08-01T16:59:09Z** — soit **après** la
  publication de 1.9.1 (2026-07-31). **Le bug est donc présent dans la version installée.** Or
  notre `.planning/WINDOWS.md` porte précisément de la prose sous son ledger.
- Accessoirement, [#2787](https://github.com/open-gsd/gsd-core/issues/2787) (la description de la
  capability surestime l'enforcement, elle affirme encore « Blocks /gsd-ship while any window is
  open » sans mentionner l'opt-in) n'est corrigée en amont que depuis le 2026-08-03 : la
  description mensongère est elle aussi encore dans le payload installé.

> **Conséquence** — **la zone 2 option C n'est pas exécutable sur `gsd-core@1.9.1`.** Toute
> activation de `windows_enforce` (et tout `windows waive`) doit être **gatée sur une montée de
> `gsd-core` au-delà de 1.9.1**. C'est une **décision supplémentaire** que le cadrage n'avait pas
> identifiée : monter le moteur, ou différer la zone 2.

### 3. `context:` — la clé n'est même pas celle qu'on croit

Le schéma amont porte **deux clés distinctes** : `context` (texte libre injecté dans chaque prompt,
sans rapport) et **`context_profile`** (les presets `dev`/`research`/`review`, « *Added in v1.34* »).
Or les trois fichiers livrés déclarent en en-tête « *Loaded when `context: dev` is set* » — ils
**nomment une clé qui ne porte pas cette sémantique dans le schéma**. Et `context_profile` : **6
occurrences amont, toutes dans `docs/`** ; zéro dans `src/`, `workflows/`, `agents/`, `bin/`. Les
trois fichiers n'ont été touchés que deux fois dans toute l'histoire du dépôt — création le
2026-04-05, renommage de répertoire le 2026-06-02. **Quatre mois sans une seule modification
fonctionnelle.** Zéro dépréciation, zéro issue, zéro PR : le tiroir est ouvert et vide dans les
deux sens.

> **Conséquence** — la capacité n'est **ni dépréciée ni en chantier** : troisième état,
> **documentée, livrée, jamais câblée, abandonnée de fait**. L'ADR de la zone 4 se rédige en refus
> **définitif dans son motif** (« il n'y a rien à activer ») mais assorti d'un **déclencheur de
> réexamen objectif, pas d'une date** : rouvrir ssi `context_profile` apparaît hors de `docs/` dans
> une release, ou qu'une issue amont le mentionne. **Ne jamais écrire « déprécié »** — l'amont ne
> l'a jamais dit, l'ADR serait factuellement faux. Bonus actionnable : le désalignement
> en-tête ↔ schéma est un signalement amont propre et peu coûteux, du gabarit de #2787.

### 4. Le canal de remontée amont est vivant, et personne n'a posé le cas Claude Code

Utile aux voies « remontée upstream » (M2 voie 2, déjà retenue, et zone 5 option D) :
**[#853](https://github.com/open-gsd/gsd-core/issues/853) est CLOSED depuis le 2026-06-08** — mais
le correctif **n'a pas corrigé la limitation** : il a basculé plan/execute en inline sur Claude Code
et **encodé le fait comme permanent** (`backgroundDispatch: false`), toujours vrai en 1.9.1. La
justification n'est donc **pas périmée, mais jamais re-mesurée depuis deux mois**.
[#2598](https://github.com/open-gsd/gsd-core/issues/2598) est le **précédent exact de forme
acceptée** (« bug(opencode): capability descriptor declares `backgroundDispatch:true` but dispatch
is synchronous-only ») et [#2939](https://github.com/open-gsd/gsd-core/issues/2939) est **ouverte**
sur un autre runtime (Codex) — la règle d'aplatissement est activement contestée. **Personne n'a
posé le cas Claude Code.** La remontée est légitime, sans doublon, et doit être formulée en
« **descripteur non descriptif du runtime** », jamais en « bug de comportement ».
(`#2608` est un bug de staging `git add` sans rapport, corrigé dans le 1.9.1 installé.)

---

## Écart de protocole du manager — ADR-059, à connaître

**La branche dédiée a été créée APRÈS le premier commit, pas avant.** Le commit de cadrage
`fbdb300` a donc atterri sur `main`. Remédiation appliquée : branche
`feat/phase-24-activation-moteur-gsd` créée à `fbdb300` — **tous les commits suivants de la mission
y atterrissent**.

`main` **n'a délibérément pas été réécrit** : il portait déjà **5 commits locaux non poussés qui
n'appartiennent pas à cette mission** (le quick `260804-ki4`), et rembobiner une branche partagée
sous une autre session possible n'est pas une décision que le manager prend seul. Si Samuel veut
sortir `fbdb300` de `main`, le geste est non destructif (le commit vit sur la branche de mission) :

```
git branch -f main 08a563d      # depuis une autre branche que main
```

## Arbitrages rendus par Samuel (2026-08-04) et doctrine élargie

8 arbitrages rendus en un passage : Z1=A, Z2=C, Z3=A, Z4=A, **Z5=ADOPTION (option C, contre la
recommandation D du cadrage)**, Z6=A, préalable « monter gsd-core », « pas de Phase 27 ».
Verdicts posés en tête de chaque zone de `24-ARBITRAGES.md` (commit `bb29d35`).

**Doctrine élargie « GSD-first »**, posée après les arbitrages : les choix suivent l'**usage réel de
GSD** plutôt que la conformité aux ADR/Iron Laws internes ; **toute collision se CONSIGNE
(`24-COLLISIONS.md`), jamais ne se contourne en silence** ; la révision effective d'une loi reste
validée par Samuel ; ADR-031 et la release racine gatée restent en vigueur.

## Nœud `plan` — 12 plans, 4 vagues, `gsd-plan-checker` PASS

Ledger `GSDA-01..22`, couverture **22/22** vérifiée en `comm`, 0 orpheline, 0 inventée. Disjonction
des périmètres re-vérifiée indépendamment du planner : **0 collision dans chacune des 4 vagues**.

**Deux faits de recherche ont falsifié des prémisses d'arbitrage :**

1. **Il n'existe AUCUNE version de `@opengsd/gsd-core` au-delà de `1.9.1`** (`dist-tags.latest =
   1.9.1`, 2026-07-31 ; PR #2975 mergée le 2026-08-01, après ; `dist-tags.next = 1.7.0-rc.6`,
   antérieur). **Le prérequis dur de la zone 2 est insatisfiable** → clause de repli `GSDA-01` :
   zone 2 différée, déclencheur objectif gravé.
2. **Notre `WINDOWS.md` ne porte AUCUNE prose sous son ledger** (87 l., en-tête identique au rendu
   canonique). La prémisse qui motivait le prérequis est donc **fausse en l'état** : un `waive` ne
   détruirait rien aujourd'hui. Confirmé au passage que `waive` porte la **même** destruction
   qu'`append` (`writeLedgerAtomic` → `renderLedger` réécrit intégralement).

**Défaut réel trouvé et corrigé au plan** : `24-10` ancrait sa garde « aucune phase ajoutée » sur
`### Phase ` seul → comptait **13** au lieu de 26 (le ROADMAP mêle `###` et `####`). Aurait rougi à
tort et poussé un exécuteur à « réparer » un ROADMAP intact.

## Vague 1 exécutée — 4 plans en parallèle, périmètres disjoints

`24-01` (`effort:` × agents, `check-agents.sh` durci, marge de dispatch) · `24-03` (slot
`agent_skills.gsd-planner`, §10 de `GSD-PIPELINE.md`) · `24-04` (3 gates workstream-aware) ·
`24-05` (gate sur le pointeur + hook `SessionStart`). **25 commits** depuis le plan.

### Les juges ont trouvé ce que les 4 workers ne pouvaient pas voir

Revue de jointure + audit dispatchés **en parallèle** (juges read-only). Les deux convergent : *les
lots pris isolément sont bien faits, c'est la **composition** qui casse.*

- **La population d'agents est 31, pas 25.** L'installeur copie aussi chaque `plugin/*/AGENT.md`
  dans `.claude/agents/` (`vibeflow-update.sh:479`). **5 des 6 `AGENT.md` sans `effort:`** →
  **CI Gate C rouge** (`ci.yml:328`, sous `set -eu`) et T20 en KO. Deuxième fois que ce dépôt se
  fait avoir par un **univers de liste sous-estimé**.
- **`check-state-integrity.sh` — 3 faux verts + 1 faux rouge** sur le gate ADR-063 : handler de
  rejet **fail-open**, test de vacuité avant le trim, borne locale de 80 caractères **non-amont**
  (`isValidActiveWorkstreamName("a"×100)` = `true` en amont), et absence de précondition de
  partitionnement.
- **`check-workstream-pointer.sh` rendait « conforme » sur `..` et `.`**, et **fabriquait un vert
  sur un nom qu'il avait lui-même réécrit** (`tr -d ' '` supprimait tous les espaces : un pointeur
  `de v` devenait `« dev »`).
- **Fuite d'information au `SessionStart` par symlink versionné** — motif de la Phase 23 rouvert
  **et élargi** : auto-déclenché, sans borne, la 1ʳᵉ ligne du fichier cible réimprimée verbatim
  dans le contexte de session.
- **Le gate CI anti-régression ADR-063 se désarmait par `export`** (`ci.yml:293` sans `--file`).
- **Cause commune de la divergence** : 4 copies de la politique de nom en 2 variantes, écrites
  contre deux lectures différentes du même fichier amont — **aucune correcte**.

### Correction ciblée — un seul `reopen`, 6 bloquants fermés par mutation

Findings des deux juges **fusionnés et dédoublonnés** avant un `reopen` unique (jamais un par
juge). Fermetures **prouvées par mesure, pas par relecture** : Gate C `CI_GATE_EXIT=0` (et `1` sous
mutation), T20 vert, suite dev-orchestrator **165 OK / 0 KO**, les 3 faux verts et le faux rouge
inversés, `..`/`.`/`.hidden`/`-x`/`de v` tous passés en `2`, fuite symlink refermée et **garde
isolée par mutation** (`-L` retiré → la fuite réapparaît). **49 suites découvertes, 0 échec.**

La politique de nom est désormais **écrite une seule fois** dans une lib sourcée partagée —
dépendance inter-modules vérifiée tenable contre l'hypothèse initiale — avec une suite de 13 cas
dont un **différentiel contre le vrai `workstream-name-policy.cjs`** (verdict identique sur 19
noms) et une preuve d'**identité de classification des 4 gates**.

**Contradiction de mesure tranchée par re-mesure** : `24-03` annonçait 165/0, `24-04` 164/1 sur la
même suite. La baseline était **164/1** — la mesure de `24-03` n'était pas fausse, elle a été
**invalidée après coup** par le commit `a29cd60` d'un autre lot. Défaut de jointure, pas de plan.

## Vague 2 — deux lots sur trois livrés

Samuel a **dégelé la zone 2** (le prérequis « monter gsd-core » étant insatisfiable — `latest = 1.9.1`,
aucune version au-delà — et le risque #2893 sans objet ici, `WINDOWS.md` ne portant aucune prose sous
son ledger) et **amendé ADR-064** (`GSD_WORKSTREAM` devient le canal nominal, composable avec les
worktrees). Deuxième révision doctrinale autorisée de la phase, après l'Iron Law 2.

- **`24-02` — zone 2 activée.** Dérogation de la fenêtre #3 jouée après répétition sur copie jetable :
  `open_count 1 → 0`, `waived_count 0 → 1`, **miroir JSON intact, 4 entrées `fixed` préservées, 87
  lignes avant comme après — le bug #2893 ne s'est pas manifesté.** `windows_enforce` et
  `workflow_guard` posés (diff de 2 lignes, `auto_advance`/`_auto_chain_active` toujours `false`).
  ADR-066 et ADR-067 écrits. **Le gate de ship a été vérifié par la requête qu'exécute le workflow
  lui-même** (`loop render-hooks ship:pre --raw` → `broken-windows, blocking=true`), avec
  contre-épreuve sans la clé — pas par relecture de la config.
- **`24-08` — workstreams câblés dans les agents.** `references/workstreams.md` créé (135 l.), renvois
  courts dans `vf-dev-manager.md` (**248/250, marge 2**) et `vf-coder.md` (107/250). Fait re-vérifié en
  direct : sans canal, `getActiveWorkstream` rend `null` alors que le pointeur contient `dev`.
- **`24-09` — NON LIVRÉ.** Deux mandats coupés par des erreurs réseau (`Response stalled mid-stream`),
  **aucun commit, arbre propre de son périmètre, aucun état partiel à réconcilier.** Échec
  d'infrastructure, pas de conception : les deux mandats étaient arrivés au banc de mutation.

### ⚠️ Deux propagations DUES, non faites — landmines pour la prochaine session

Elles étaient jointes au mandat `24-09` et sont tombées avec lui.

**P1 — un contrôle négatif est INVERSÉ et fera échouer `24-06` puis `24-12`.** Le plan `24-02` a été
exécuté **contre trois de ses propres `must_haves`** (le dégel est arrivé après sa rédaction). Son
`<verification>` déléguait à `24-03`, `24-06` et `24-12` le contrôle « les deux clés sont **absentes**
du `config.json` » — elles y sont désormais **présentes et à `true`**. Occurrences localisées en `awk` :

- `24-03-PLAN.md:98` — `jq -e` de contrôle négatif (plan déjà exécuté ; à corriger pour que sa
  relecture ne soit pas trompeuse)
- `24-06-PLAN.md:100` — « les quatre contrôles négatifs de 24-03 tiennent toujours » → **bloquant**
- `24-02-PLAN.md:211` et `:254` — texte historique, à annoter plutôt qu'à réécrire
- `24-12` — **non trouvé par cette sonde, à re-dériver** avant exécution

**P2 — le chiffre de couverture des workstreams n'est pas reproductible.** L'arbitrage et
`24-COLLISIONS.md` citent **7/91 conscients (7,7 %)** et 42 aveugles. Re-mesure indépendante en
`awk`+`comm` par le worker `24-08` : **5 conscients (5,5 %)** — `new-milestone`, `settings`,
`settings-advanced`, `settings-integrations`, `transition` — **45 en dur dont 43 aveugles**. Aucun
motif alternatif ne remonte à 7. L'écart va **dans le sens du pire**, il ne fragilise donc pas
l'adoption — mais **ADR-069 (plan `24-10`) s'apprête à graver « les limites connues datées »** et ne
doit pas inscrire un chiffre invérifiable. À re-mesurer une troisième fois, puis inscrire avec sa
méthode et sa date, **la valeur périmée conservée et attribuée à sa source**.

### Autres constats de la vague 2

- **`ADR-065` n'existe pas** : le registre saute de 064 à 066. Trou réel, non comblé (hors périmètre).
- **La mesure « 23/109 commits » de l'arbitrage n'est pas reproductible** (aucun range git ne rend 109).
  Le worker `24-02` a rejoué sur un corpus nommé, **en caractères et non en octets** (un décompte en
  octets gonfle les sujets français et fabriquerait un faux motif) : **275/400 = 68 %** au-delà de
  72 caractères, **65/400 = 16 %** hors liste amont, les 6 types maison confirmés. Conclusion
  identique, chiffre honnête — c'est celui qu'ADR-067 porte.
- **Piège outillé à connaître** : `check-agents.sh` n'accepte que `--agents-dir=PATH` (forme `=`). Avec
  un espace, il rend **exit 3 sur les 6 dossiers** — un faux rouge indiscernable d'un parc non conforme.

## Points ouverts, non tranchés par cette mission

- **Recalage du ROADMAP** — 8 faits périmés dans la section Phase 24. Différé au nœud `docs` de fin
  de mission (documenter des états intermédiaires périmés à chaque étape serait du travail jeté).
- **`plugin/software-architecture/rules/production-code-architecture.md:2-11`** — path-scope
  `src|app|lib|features` inexistant dans ce dépôt, règle dormante. **Hors des 11 items de la
  phase** : porté au backlog, pas traité ici.
- **`WINDOWS.md` fenêtre #3** — recette XcodeBuildMCP infermable dans ce dépôt ; elle appartient à
  un lab iOS équipé. Sa dérogation est conditionnée à la zone 2.
- **Release racine** — hors périmètre par consigne. Si la phase aboutit à un bump de `VERSION`, le
  tag annoté + la release GitHub + `check-release-tag --remote` restent un geste humain.
