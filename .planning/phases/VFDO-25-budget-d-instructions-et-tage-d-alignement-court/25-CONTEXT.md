# Phase 25: Budget d'instructions - Context

**Gathered:** 2026-09-14
**Status:** Ready for planning — la **calibration** (valeurs de baseline) n'est exécutable qu'après la clôture de la Phase 34 (D-06, close le 2026-09-15) **et la livraison de la Phase 40** (D-06 bis, 2026-09-15)

<domain>
## Phase Boundary

La phase livre **un gate machine** qui mesure et publie, pour chaque fichier d'agent distribué, la
**charge d'instructions** (formes normatives comptées) **et** le **nombre de lignes** (ADR-029,
jusqu'ici jamais machine-enforced par un gate distribué), avec un **seuil en ratchet** : baseline
posée sur le corpus final du milestone, avertissement d'abord, blocage au merge qui livre la
remédiation, jamais rouge des semaines. Exigences : `BUDG-01`, `BUDG-02`, transverse `QUAL-01`
(trois issues, imparsable bruyant, mutation rouge prouvée).

Hors périmètre (périmètre réduit du 2026-08-15, `.planning/ROADMAP.md:908-911`) : `BUDG-03` / G2
étage d'alignement court (différé, Out of Scope du ledger), budget des `SKILL.md` et du bootstrap,
métrique en tokens, toute réécriture d'agent pour « passer » — la remédiation d'un fichier est un
geste ultérieur, pas un livrable de la phase.

</domain>

<decisions>
## Implementation Decisions

Cinq arbitrages rendus par Samuel le **2026-09-14** (AskUserQuestion, session principale), en un
lot groupé puis une question de bouclage. Ils sont **verrouillés** — ne pas les rouvrir.

### Métrique BUDG-01 — formes normatives comptées
- **D-01:** Une **instruction** = une ligne du **body** (hors frontmatter YAML) qui porte un
  **marqueur normatif** — liste versée au gate, re-dérivable, insensible à la casse, FR + EN :
  `JAMAIS`, `TOUJOURS`, `NE … PAS`, `DOIT`, `MUST`, `NEVER`, `ALWAYS`, `interdit`, `obligatoire`
  (liste de départ = celle de la mesure du 2026-09-14 ; le plan peut l'étendre, jamais la réduire
  sans consigner pourquoi) — **ou** une puce impérative sous un titre de règles (forme à préciser
  au plan, avec contrôle positif et négatif). Le compte est **par fichier**, publié dans la sortie
  du gate. La métrique **tokens estimés** (piste F3, `.planning/research/FEATURES.md:68-87`) est
  **écartée** : elle mesure la taille, pas l'adhérence — c'est exactement le défaut d'ADR-029 que
  la phase corrige (`.planning/ROADMAP.md:912-915`). — **Reversibility:** costly — la définition
  fonde la baseline (D-02) ; la changer après armement invalide toutes les valeurs publiées.
- **D-02:** **Seuil = baseline par ratchet vers le bas.** Au jour 1, le seuil de chaque fichier
  vaut son **maximum mesuré sur le corpus final** du milestone (aucun rouge à l'armement) ; une
  baseline **ne peut que descendre** ; **toute hausse d'un fichier au-dessus de sa baseline
  rougit** une fois le gate armé. Le seuil absolu « ~150-200 instructions » de la source est
  **écarté** : le max mesuré aujourd'hui est **44** (`vf-dev-manager.md`), un tel seuil serait vert
  partout, donc **inerte** — le mode d'échec d'ADR-059 que ce milestone a déjà payé. Le seuil par
  rôle (managers / workers) est écarté aussi : la baseline par fichier le rend inutile. —
  **Reversibility:** costly — les baselines sont un contrat publié (README, CHANGELOG) ; une
  remontée demanderait un arbitrage humain consigné.

- **D-01 bis — ratification datée (arbitrage Samuel, AskUserQuestion session principale,
  2026-09-15) :** le comptage est **body seul, hors frontmatter YAML**, à la lettre de D-01. Les
  chiffres cités en D-03 (463 instructions, 44 pour `vf-dev-manager.md`) venaient d'un comptage
  brut incluant le frontmatter (les champs `description:` portent eux-mêmes des marqueurs) ; la
  mesure body-only de `25-RESEARCH.md` donne **433 / 43**. Le plan `25-01` implémente le texte,
  pas le chiffre — hypothèse signalée #1 du plan, **ratifiée** ; le checkpoint de calibration
  (`25-04`) n'a plus à la reposer. — **Reversibility:** costly après gravure (D-02).

### Portée
- **D-03:** **Agents distribués seulement** : les fichiers `plugin/*/agents/*.md` (25 au
  2026-09-14) et `plugin/*/AGENT.md` (6), soit **31 fichiers, 3 603 lignes, 463 lignes
  impératives** au comptage brut du 2026-09-14. **Découverte non vide obligatoire** (0 fichier
  découvert = issue « non vérifiable », jamais un vert). `SKILL.md` et bootstrap : hors phase,
  consignés en dette (voir `<deferred>`).

### Ratchet BUDG-02 — sentinelle versionnée, patron Phase 18
- **D-04:** Le ratchet suit **le seul précédent maison** : `check-requirements-survival.sh`
  (`plugin/dev-orchestrator/scripts/check-requirements-survival.sh:14-31`) — un **fichier-sentinelle
  versionné** (`.planning/.instruction-budget-armed` ou nom équivalent, **lu, jamais écrit par le
  gate**, doctrine `plugin/dev-orchestrator/AGENT.md:139-146`). **Non armé → exit 3, rapport
  imprimé intégralement** (avertissement audible, jamais silencieux) ; **armé → bloquant** en CI.
  L'armement se fait **dans le même commit que la remédiation** (spec Windows II §7,
  `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md:381-383`) — ici, le commit
  qui grave les baselines. Les alternatives « baseline par fichier style size-limit » (sans
  avertissement préalable) et « condition CI PR/main » (aucun précédent dans `ci.yml`) sont
  écartées. — **Reversibility:** reversible — désarmer = retirer la sentinelle, geste visible en
  diff.

### ADR-029 — les 250 lignes deviennent machine-enforced, même gate, même ratchet
- **D-05:** Fait d'entrée établi le 2026-09-14 : **aucun gate distribué ne mesure le plafond de
  250 lignes** — `check-agents.sh` ne compte ni lignes ni instructions (0 occurrence de seuil sur
  708 L), seule la suite `test-dev-orchestrator.sh` (T3/T5, `:28-36,1085`) le fait pour son propre
  module ; `plugin/conductor/README.md:95-99` attribue à tort un « budget de préchargement » à
  `check-agents.sh`. **Décision : le gate budget publie lignes ET instructions par fichier ; le
  plafond de lignes (250, agents) est armé par la même sentinelle** ; le README conductor est
  **corrigé** dans la phase. Une seule brique, deux métriques, trois issues chacune. Les options
  « hors Phase 25 » et « deux scripts distincts » sont écartées.

### Séquencement avec la Phase 34
- **D-06:** Cadrage rendu **maintenant**, planification **possible dès maintenant** ; la **tâche de
  calibration** (mesure du corpus, gravure des baselines, armement) **n'est exécutable qu'après la
  clôture de la Phase 34** (`.planning/ROADMAP.md:919-921`, critère 3) — le seul ajout d'agents
  possible en 34 est `web-test-team` sur run mobile vert. Le plan porte cette dépendance comme un
  **checkpoint bloquant**, pas comme une note. Tout ce qui précède la calibration (script, suite,
  trois issues, mutation rouge, câblage CI en mode non armé, README) peut s'exécuter avant. —
  **Reversibility:** one-way — graver les baselines sur un corpus qui bouge ensuite rendrait la
  publication fausse dès la première hausse ; c'est le motif même de la dépendance.

### Amendement daté — séquencement avec la Phase 40 (2026-09-15)
- **D-06 bis (arbitrage Samuel, AskUserQuestion session principale, 2026-09-15) :** la Phase 34 est
  close et mergée (PR #66) **sans aucun agent créé** — mais la **Phase 40** (inscrite le 2026-09-15,
  `40-CONTEXT.md`) réécrit `plugin/dev-orchestrator/AGENT.md` (renommage `vibeflow-head` +
  extension de rôle), donc change les lignes et les instructions d'un fichier du corpus. Décision :
  **tout construire maintenant** (script, suite, trois issues, mutation rouge, câblage CI en mode
  non armé, README, note ADR-029) dans une première PR ; la **tâche de calibration** (mesure du
  corpus, gravure des baselines, armement de la sentinelle) reste un **checkpoint bloquant** où le
  manager de mission s'arrête et rend son rapport — elle s'exécute dans une **seconde PR, après la
  livraison de la Phase 40**. La dépendance ROADMAP « Phase 34 **et Phase 40** » (amendée le
  2026-09-15) est la source. — **Reversibility:** reversible — calibrer plus tôt reste possible sur
  arbitrage humain nommé, au prix d'une baseline à remonter à la 40.

### QUAL-01 (transverse, critère de chaque gate du milestone)
- Le gate naît avec ses **trois issues** — PASS / FAIL / **imparsable BRUYANT** (un frontmatter
  YAML cassé ou un body illisible = « non vérifiable », **jamais compté vert**,
  `.planning/REQUIREMENTS.md:1083`, `.planning/ROADMAP.md:538-540,936-937`) — et sa **mutation
  rouge prouvée** (patron Phase 39 : mutant vérifié muté par `cmp`, rouge sur l'original et vert à
  tort sur le mutant).

### Claude's Discretion
- Nom et emplacement du script (`plugin/conductor/scripts/check-instruction-budget.sh` est la
  lecture naturelle — gates machine du conductor, `README.md:86-120`), forme du fichier de
  baselines (versionné, lisible en diff, une ligne par fichier).
- Forme exacte de la « puce impérative sous un titre de règles » (D-01) et contrôles associés.
- Rendu de la sortie (tableau fichier | lignes | instructions | baseline | verdict).
- Étape CI : pattern d'étape simple `.github/workflows/ci.yml:329-332,342-367` avec le commentaire
  « POURQUOI CE GATE EXISTE », découverte non vide assertée, exit 2/3 traités selon l'état armé.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Périmètre et exigences
- `.planning/ROADMAP.md` § Phase 25 (`:908-937`) — origine (2026-07-31), périmètre réduit, goal, dépendance à la 34, trois critères, transverse QUAL-01.
- `.planning/REQUIREMENTS.md:949-951` — `BUDG-01`, `BUDG-02` ; `:1083` — `QUAL-01` texte exact ; `:851` — statut QUAL-01 (reste à tenir sur 33, 18, 25) ; `:1096-1097` — anti-features « blocage CI dur immédiat » et « BUDG-03 différé ».
- `.planning/research/ARCHITECTURE.md:69` — siège du gate (conductor) ; `.planning/research/FEATURES.md:68-87` — piste F3 (écartée, mais à citer comme option refusée).

### Précédent ratchet et doctrine des gates
- `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md:366-384` — §7 avertissement d'abord, blocage dans le commit de remédiation.
- `plugin/dev-orchestrator/scripts/check-requirements-survival.sh:14-31,113` ; `plugin/dev-orchestrator/scripts/requirements-survival-detect.sh:80` ; `plugin/dev-orchestrator/AGENT.md:139-146` — sentinelle lue, jamais écrite.
- `.planning/ROADMAP.md:538-540` — « l'imparsable n'est jamais un vert par défaut » ; `.planning/research/PITFALLS.md:277,436`.
- `plugin/conductor/scripts/check-divergence.sh` (Phase 39) — codes de sortie tous énumérés, `2` non vérifiable ; `plugin/conductor/scripts/tests/test-check-divergence.sh` — patron de mutants vérifiés par `cmp`.

### Densité ADR-029 et état réel de l'enforcement
- `docs/ADR.md:52` — ADR-029 (index seul, aucun corps) ; `plugin/reference/content/methodology/patterns/03-agents.md:110-114` ; `docs/reference/methodology/templates/skills/agent-density-auditor/references/thresholds.md:7-24` — paliers OK/WARN/HEAVY/CRITICAL (template non distribué).
- `plugin/conductor/scripts/check-agents.sh:23-46,75-77` — contrat réel (aucun comptage) ; `plugin/conductor/README.md:95-99` — affirmation à corriger ; `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:28-36,1085,1196` — seul enforcement existant, mono-module.
- `plugin/software-architecture/scripts/check-file-size.sh:11-27` — compteur de lignes existant (code seulement, marqueur `vibeflow:allow-large-file`) : patron de marqueur d'exception, pas de réutilisation directe.

### Câblage CI et documentation
- `.github/workflows/ci.yml:244-251` (job `gates`), `:252-321` (boucles agents, découverte non vide), `:329-332,342-367` (pattern d'étape simple), `:350-351,366-367` (exit 2/3 = échec).
- `plugin/conductor/README.md:86-120` — catalogue des scripts ; `scripts/check-version-sync.sh` — compteur de suites des README à re-dériver.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `check-requirements-survival.sh` + sentinelle : le mécanisme de ratchet à cloner (cinq issues déclarées, exit 3 non armé).
- `check-divergence.sh` / `test-check-divergence.sh` : le patron « codes énumérés + mutants `cmp` » le plus récent du dépôt.
- Mesure brute du 2026-09-14 (31 fichiers, motif `JAMAIS|TOUJOURS|NE .* PAS|DOIT|MUST|NEVER|ALWAYS|interdit|obligatoire`) : 3 → 44 instructions par fichier, ratio 4 % → 26 %, `vf-dev-manager.md` à 250/250 L et 44 instructions — le fichier qui bornera la baseline.

### Established Patterns
- Un gate imprime tout ce qu'il mesure ; un compteur qui rend 0 sur découverte vide est un vert à vide (`[[preuve-incapable-de-rendre-rouge]]`).
- Marqueur d'exception explicite et greppable (`vf-allow-machine-path`, `vibeflow:allow-large-file`) si une ligne doit être exclue du comptage — jamais une exclusion implicite.
- Tout script conductor est catalogué dans `plugin/conductor/README.md` et bumpe le module (minor pour un gate neuf).

### Integration Points
- Job `gates` de `ci.yml` (étape dédiée) ; `plugin/conductor/README.md` (catalogue + correction de l'affirmation sur `check-agents.sh`) ; `README.md`/`README.fr.md` (compteur de suites) ; `.planning/REQUIREMENTS.md` (QUAL-01 statut) ; `docs/ADR.md` (note datée sous ADR-029 : enforcement machine à partir de cette phase).

</code_context>

<specifics>
## Specific Ideas

- « Une seule brique, deux métriques » : le rapport du gate montre côte à côte lignes et instructions par fichier, chacune face à sa baseline.
- Le fichier de baselines doit se lire en diff comme un contrat : une ligne par fichier, valeurs entières, abaissement = commit de remédiation, jamais de hausse sans arbitrage humain nommé (canal + date, convention `CLAUDE.md`).
- Le contrôle négatif de la métrique fait partie de la preuve : une ligne descriptive contenant un marqueur hors contexte normatif (ex. citation) doit être discutée et tranchée au plan, pas ignorée.

</specifics>

<deferred>
## Deferred Ideas

- **Budget des `SKILL.md` (≤ 500 L) et du bootstrap (≤ 2000 tokens)** — même absence d'enforcement machine, hors périmètre BUDG-01 ; dette à inscrire au BACKLOG.
- **Métrique en tokens estimés** (F3) — écartée, pas différée : à ne rouvrir que sur incident lié à la taille plutôt qu'à l'adhérence.
- **BUDG-03 / G2 étage d'alignement court** — Out of Scope du ledger, inchangé.
- **Remédiation des fichiers les plus chargés** (`vf-dev-manager.md`) — geste ultérieur, par lot, chacun abaissant une baseline.

</deferred>

---

*Phase: 25-budget-d-instructions-et-tage-d-alignement-court*
*Context gathered: 2026-09-14*
