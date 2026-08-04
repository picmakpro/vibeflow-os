# Phase 24: Activation et mesure du moteur GSD — capacités dormantes et faits de runtime - Context

**Gathered:** 2026-08-04
**Status:** ⚠ EN ATTENTE D'ARBITRAGE — voir `24-ARBITRAGES.md`

> **Ce cadrage n'est PAS complet.** Il a été produit par un worker interne (`vf-coder`) qui n'a pas
> d'outil de question. Les 6 zones grises ont été instruites et documentées, **aucune n'a été
> tranchée**. Les décisions ci-dessous sont donc de deux natures, jamais mélangées :
> les **F-xx** sont des **faits re-vérifiés sur disque** le 2026-08-04 (opposables, pas des choix) ;
> les **D-xx** sont **absents** tant que Samuel n'a pas répondu aux 6 questions de
> `24-ARBITRAGES.md`. Aucune décision n'a été auto-répondue en silence.

<domain>
## Phase Boundary

Cette phase **constate, mesure et décide** — elle n'active rien par elle-même. Elle porte sur
**11 items** : le lot MESURE (M1, M2, M3) et le lot ACTIVATION (A1 → A9). Chaque item est une
brique du moteur `@opengsd/gsd-core` **présente sur le disque**, dont le toggle est à `false` ou
dont le canal est vide, et que VibeFlow soit ignore, soit ré-implémente à la main.

**Ce que la phase livre** : pour chaque item, une décision arbitrée (activer / refuser / borner) et
son écriture — clé de config, ligne de doctrine, cas de test, ou ADR. **Ce qu'elle ne livre pas** :
aucune nouvelle capacité, aucun fork d'un mécanisme GSD (ADR-030), aucun verbe-façade.

**Ordre imposé par le ROADMAP** : le lot MESURE d'abord. M2 est **déjà mesuré et arbitré**
(2026-07-31, preuve : `.planning/missions/2026-07-31-mesure-m2-dispatch-parallele.md`, voies 1 et 2
retenues, voie 3 écartée) — il ne se rediscute pas. M1 et M3 restent à instruire, et sont regroupés
en zone 6 ci-dessous.

**Hors périmètre, explicitement** : la Phase 25 (budget d'instructions et étage d'alignement court)
— la frontière 24/25 est documentée dans le ROADMAP et ne se franchit pas ; la release racine
(bump `VERSION` + tag + release GitHub), réservée à un geste humain ; toute partition de
`.planning/` tant qu'une phase est en vol (cf. F-24, divergence invisible).

</domain>

<decisions>
## Faits re-vérifiés (F-xx) — établis sur disque le 2026-08-04

> **Aucun fait du ROADMAP n'a été recopié.** Chaque assertion ci-dessous a été re-testée contre les
> fichiers réels. Les faits du ROADMAP dataient du **2026-07-31** contre `gsd-core@1.9.0` ; la
> machine tourne aujourd'hui en **1.9.1**. **8 faits sur 23 ont péri en 4 jours.**

### Socle — l'environnement mesuré

- **F-01 [PÉRIMÉ] :** `gsd-core` installé est en **1.9.1**, pas 1.9.0
  (`~/.claude/gsd-core/VERSION`). Tous les faits du ROADMAP sont donc établis contre une version
  qui n'est plus celle du disque. Le payload utile est sous `~/.claude/gsd-core/bin/lib/`
  (**segment simple** — c'est le tarball npm, non installé, qui porte le double segment
  `gsd-core/gsd-core/bin/lib` ; ne jamais conclure « absent » depuis l'un ou l'autre seul).
- **F-02 [CONFIRMÉ] :** **44 capabilities** et **12 points de hook** exactement, chargés depuis
  `~/.claude/gsd-core/bin/lib/capability-registry.cjs` (`capabilities`, `byLoopPoint`,
  `capabilityClusters` — 8 clusters). Le compte n'a pas bougé de 1.9.0 à 1.9.1.
- **F-03 [PÉRIMÉ] :** `.planning/config.json` a évolué depuis la Phase 23 : les blocs `gates` et
  `safety` ont été **supprimés**, `_auto_chain_active: false` et `auto_advance: false` sont posés
  explicitement, `agent_skills: {}` est **vide**. Aucune des clés de la Phase 24
  (`workflow.windows_enforce`, `workflow.tdd_mode`, `intel.enabled`, `graphify.enabled`,
  `profile-pipeline.enabled`, `context`, `workflow.inline_plan_threshold`, `hooks.community`,
  `hooks.workflow_guard`) n'y figure — **toutes tombent sur leur défaut**.
- **F-04 [PÉRIMÉ] :** le dépôt est en **v2.47.1** (`VERSION`), pas v2.47.0 — PR #33 mergée le
  2026-08-04.

### M1 — profondeur de dispatch

- **F-05 [CONFIRMÉ] :** le descripteur `claude.runtime.hostIntegration.dispatch` de la 1.9.1 est
  **inchangé** : `{ namedDispatch: true, nested: true, maxDepth: 5, background: true,
  backgroundDispatch: false, subagentToolkit: "full", isolation: "harness-worktree" }`. La chaîne
  `vf-dev-manager → vf-coder → agent gsd-*` consomme **3 niveaux sur 5** : deux de marge.
- **F-06 [CONFIRMÉ] :** `shouldFlattenDispatch()` est bien à `host-integration.cjs:464`. M2 tient.

### M3 — `effort:`

- **F-07 [CONFIRMÉ, avec une précision qui change la donne] :** sur les **25 agents livrés** par les
  modules (`plugin/*/agents/*.md`, sonde littérale du ROADMAP), **0 déclare `effort:`** — le
  constat tient. **Mais** la sonde élargie (`plugin/**/agents/*.md`, 49 fichiers) trouve **3
  agents-templates qui en portent déjà un** :
  `plugin/reference/content/methodology/templates/agents/business-agent-template.md` (`medium`),
  `clarity-feature-template.md` (`high`), `orchestrator-template.md` (`high`). **Le barème par rôle
  existe donc déjà en germe dans nos propres templates** — les modules ne l'ont simplement jamais
  appliqué à leurs agents. Ce n'est plus une doctrine à inventer, c'est une doctrine à propager.
- **F-08 [CONFIRMÉ] :** notre gate valide déjà `effort:` — `check-agents.sh:514-516`,
  `low|medium|high|xhigh|max`. Le harness l'expose (`agentFrontmatterExtensions: ["effort"]`,
  descripteur `claude`).

### A1 — broken-windows

- **F-09 [PÉRIMÉ] :** `.planning/WINDOWS.md` porte **`open_count: 1`**, pas 2
  (`fixed_count: 4`, `total_count: 5`, `last_updated: 2026-07-31T19:00:00Z`). La seule fenêtre
  encore ouverte est **#3** : recette humaine différée sur `test_sim`/`build_sim`/`clean` contre un
  serveur XcodeBuildMCP vivant — **non fermable dans ce dépôt** (aucun `.mcp.json`, aucun lab iOS).
  **Conséquence directe sur l'arbitrage :** activer l'enforcement aujourd'hui **bloquerait
  `/gsd-ship` sur une fenêtre que ce dépôt ne peut structurellement pas fermer.**
- **F-10 [CONFIRMÉ] :** le gate existe et sa forme correspond exactement au ledger — capability
  `broken-windows`, `point: ship:pre`, `predicate: artifact-frontmatter-equals`,
  `artifact: WINDOWS.md`, `field: open_count`, `equals: 0`, `when: workflow.windows_enforce`,
  `blocking: true`, `onError: halt`. Défaut de la clé : **`false`**, description amont citant
  l'issue **#1950** (« teams can adopt tracking before enforcement »).

### A2 — `agent_skills`

- **F-11 [CONFIRMÉ] :** `buildAgentSkillsBlock` est bien à `init.cjs:1731`, **17 slots** exactement
  (`ADVISOR ANALYZER AUDITOR CHECKER DEBUGGER EXECUTOR FIXER MAPPER PLANNER RESEARCHER REVIEWER
  ROADMAPPER SYNTHESIZER UI UI_CHECKER UI_REVIEWER VERIFIER`), et la forme plugin-namespacée
  `global:<plugin>:<skill>` est acceptée (`init.cjs:1765-1788`).
- **F-12 [PÉRIMÉ] :** les workflows consommateurs sont **30**, pas 19 (28 au niveau racine + 2
  sous-étapes). Le canal a **grossi** entre 1.9.0 et 1.9.1.
- **F-13 [FAIT NOUVEAU, non vu par le ROADMAP — décisif] :** le slot `AGENT_SKILLS_EXECUTOR` n'est
  injecté que dans le **prompt de dispatch** de `execute-phase.md` (chargement `:86`, injection
  `:715`) ; `execute-plan.md` n'en porte aucune injection. Or `gsd-executor` et `gsd-planner` ont
  été **retirés de l'allowlist `tools:` de `vf-coder`** en Phase 23 (vérifié de première main : le
  frontmatter effectif de `vf-coder` ne les contient pas), et le repli documenté d'`execute-phase`
  quand `Agent` est indisponible est l'**exécution inline séquentielle** (`execute-phase.md:28-31`)
  — chemin **sans prompt de dispatch, donc sans injection**. **Activer `agent_skills.gsd-executor`
  risque donc d'être un vert-à-vide sur le chemin `vf-coder`.** Le slot `PLANNER`
  (`plan-phase.md:74`, injections `:769` et `:1247`) n'a pas ce problème.
- **F-14 [CONFIRMÉ] :** le digest de mission ne transmet **aucune** doctrine de dev. Ses six axes
  (`mission-contracts.md:55-63`) bornent les conventions à « 2-3 lignes du `CLAUDE.md` projet »
  (`:62`), et le `CLAUDE.md` de ce dépôt ne contient ni SOLID, ni DRY, ni KISS, ni YAGNI, ni Clean
  Archi, ni TDD. Le plafond du digest est de **≤ 30 lignes** (`mission-contracts.md:51`) — il ne
  peut structurellement pas porter la doctrine.
- **F-15 [CONFIRMÉ] :** candidats réels à l'injection, tous résolvables en `global:<nom>` (donc sans
  la forme plugin-namespacée) : `plugin/software-architecture/SKILL.md` (+ `references/solid-soc.md`,
  `principles.md`, `anti-patterns.md`), `plugin/audit-architecture/SKILL.md`, et le skill tiers
  `tdd`. **Recouvrement partiel à connaître :** `gsd-planner` reçoit **déjà**
  `.planning/codebase/CONVENTIONS.md` et `ARCHITECTURE.md` (`gsd-planner.md:635-653`) — qui portent
  densité/portabilité/commits, mais **pas** SOLID/DRY/KISS/YAGNI.
- **F-16 [FAIT NOUVEAU] :** la règle `production-code-architecture` du module est **path-scopée**
  `src/**|app/**|lib/**|features/**` (`plugin/software-architecture/rules/production-code-architecture.md:2-11`)
  — **aucun de ces dossiers n'existe dans ce dépôt** : elle y est dormante.

### A3 — `tdd_mode`

- **F-17 [CONFIRMÉ] :** `workflow.tdd_mode`, défaut `false`, absent de notre config. Contribution
  `plan:pre → planner` (fragment `<tdd_mode_active>`) + gate `execute:post`
  (`query: tdd.review-checkpoint`).
- **F-18 [FAIT NOUVEAU — réduit fortement l'enjeu] :** le gate `execute:post` de `tdd` est
  **`blocking: false`, `onError: skip`**. Et surtout : `@$HOME/.claude/gsd-core/references/tdd.md`
  (330 lignes) est déjà injecté **sans condition** dans le prompt de l'exécuteur
  (`execute-phase.md:693`). **`tdd_mode: true` n'ajoute donc pas la doctrine TDD à l'exécuteur —
  elle y est déjà.** Il ajoute exactement deux choses : le planner pose `type: tdd` sur les tâches
  éligibles, et un review-checkpoint non bloquant.
- **F-19 [FAIT NOUVEAU] :** la doctrine TDD du lab n'est pas une mécanique mais une **carte de
  20 lignes qui délègue** (`plugin/software-architecture/references/principles.md:52-72`, « Pas de
  mécanique dupliquée ici (DD3) », renvoi à `superpowers:test-driven-development`). Son critère
  d'éligibilité est **mesurable** (`:61-63`) ; celui du moteur est **par type de tâche** (business
  logic → `tdd` ; UI/config/glue/CRUD → `execute`). Sur ce dépôt (bash + markdown, suites
  `test-*.sh`), **aucune des sept catégories « TDD candidates » amont ne correspond** : l'heuristique
  du moteur classerait la quasi-totalité de nos tâches en `type: execute`, alors que notre pratique
  réelle écrit le test rouge d'abord (précédent : commit `c6585fa test(quick-260804-ki4): cas
  rouges …`).

### A4 — profils de contexte

- **F-20 [PÉRIMÉ — le fait s'inverse] :** les trois profils existent bien
  (`~/.claude/gsd-core/contexts/dev.md|review.md|research.md`) et la clé `context` est validée
  (`config.cjs:690-692`) et documentée (`planning-config.md:241`). **Mais la recherche exhaustive
  du motif dans tout `~/.claude/gsd-core`, `~/.claude/agents` et `~/.claude/skills` ne rend que
  3 hits, tous auto-déclaratifs** (la ligne 3 de chacun des trois fichiers). **Aucun consommateur
  n'existe.** Le seul `config-get context*` du moteur est `context_window` — une autre clé.
  Le ROADMAP présentait A4 comme « nous ré-implémentons en doctrine ce que le moteur porte en
  config » ; **le moteur ne le porte pas, il le déclare seulement.**
- **F-21 [CONFIRMÉ] :** incompatibilités de forme, si le canal existait : le profil est un
  **scalaire global** (une valeur pour tout le projet) alors que Pattern C
  (`mission-flow.md:136-152`) est un **contrat par rôle** (4 rôles, schéma JSON par retour) — à
  comparer avec `agent_skills`, qui est bien une map par agent. Et sur la verbosité : `dev.md:21`
  « Low » est compatible avec `mission-flow.md:139-142` (« la prose libre est du volume mort »),
  mais `research.md:20-23` « **High** … Include background context even if the developer likely
  knows it » lui est **frontalement contraire**. Vocabulaires de sévérité divergents également :
  `blocking/important/nit` amont vs `bloquant/majeur/mineur` chez nous (`mission-flow.md:148`).

### A6 — `inline_plan_threshold`

- **F-22 [CONFIRMÉ, et chiffré sur nos plans réels] :** clé `workflow.inline_plan_threshold`,
  défaut **2**, plage `0`–`10` (`references/planning-config.md:41` et `:276`), appliquée à
  `execute-plan.md:94` et `:100` (« avoids ~14K token subagent spawn overhead and preserves prompt
  cache »). **Mesure sur les 32 `*-PLAN.md` des phases 20-26**, avec la regex exacte du moteur
  (`^\s*<task[[:space:]>]`) : **0 tâche → 4 plans** (les rétro-plans de la Phase 21, sans balise
  `<task>` — artefact de format, pas petitesse), **2 tâches → 4 plans**, **3 tâches → 20 plans**,
  4 → 2, 6 → 2. Soit **4 plans exécutables sur 28 (14 %)** réellement sous le seuil, et un **mode à
  3 — juste au-dessus.** Le levier est donc réel mais étroit ; le porter à 3 le rendrait dominant.
- **F-23 [CONFIRMÉ] :** le seuil ne franchit pas la frontière que la voie unique protège. La
  délégation systématique vise l'**acteur** (`AGENT.md:165-166,172` ; `vf-dev-manager.md:12-14` ;
  `vf-coder.md:13-14,50-53`), pas le mécanisme interne du moteur ; le seuil est lu **dans**
  `execute-plan.md`, après que la brique a été atteinte (`GSD-PIPELINE.md:188-199`).

### A5 — hooks machine opt-in

- **F-24 [PÉRIMÉ — précision importante] :** les deux hooks sont **posés** dans
  `~/.claude/settings.json` (`PreToolUse/Bash → gsd-validate-commit.sh` et
  `PreToolUse/Bash|Edit|Write|MultiEdit → gsd-workflow-guard.js`), pas seulement « installés ».
  Ils s'**auto-gatent** sur `.planning/config.json` : `gsd-validate-commit.sh:12-17` sort 0 si
  `hooks.community !== true` ; `gsd-workflow-guard.js:70-79` (`workflowGuardEnabled`) rend `false`
  si `hooks.workflow_guard` est absent. **Les activer ne demande donc aucune édition de
  `settings.json` — une seule clé de config suffit**, et l'effet est immédiat sur toutes les
  sessions.
- **F-25 [PÉRIMÉ — le ROADMAP est factuellement faux ici] :** le ROADMAP affirme « le lab impose
  déjà des commits conventionnels en français **par consigne** — un gate existe ». **Aucun gate de
  message de commit n'existe dans ce dépôt** : les 6 `plugin/*/hooks/hooks.json` n'en déclarent
  aucun, et `scripts/hooks/pre-push` est le gate de tag de release. La convention est une **consigne
  du `CLAUDE.md`**, non outillée.
- **F-26 [FAIT NOUVEAU — décisif pour l'arbitrage] :** mesure de conformité de nos **109 commits
  locaux** (hors squash de PR) contre la regex exacte du hook amont : **23 échouent sur le type**
  (`release:`, `planning:`, `doctrine:`, `bump(...)`, `spec(...)`, `plan(...)` — six types que nous
  employons et que la liste amont `feat|fix|docs|style|refactor|perf|test|build|ci|chore` ne
  contient pas) et **76 sur 109 (69 %) dépassent 72 caractères de sujet**. **Activer
  `hooks.community` en l'état bloquerait plus des deux tiers de notre historique de style.**

### A7 / A8 — routes inertes

- **F-27 [CONFIRMÉ] :** `intel.enabled`, `graphify.enabled`, `profile-pipeline.enabled` valent
  toutes **`false` par défaut** et sont **absentes** de notre config. `.planning/intel/` n'existe
  pas.
- **F-28 [CONFIRMÉ] :** `intent-routing.md:104` route « le graphe de connaissance » →
  `gsd-graphify` et `:147` « profile ma façon de bosser » → `gsd-profile-user`. **Deux entrées de
  routage mènent à un geste inerte.**
- **F-29 [PÉRIMÉ — à la baisse, le trou est plus large que décrit] :** le ROADMAP dit « le test
  vérifie que le skill est routé, jamais que la capability est active ». Vérifié :
  `test-dev-orchestrator.sh` (5727 lignes, 150 cas `ok "`) **ne nomme ni `graphify` ni
  `gsd-profile-user` dans aucun cas** ; et `gsd-capabilities-index.md` (111 lignes, livré en
  Phase 23) **ne mentionne aucune des deux capabilities**, alors qu'il liste `intel`, `tdd` et
  `broken-windows`. Le gate T14 d'exhaustivité du routage existe bien
  (`test-dev-orchestrator.sh:1289-1321`) mais compte les briques routées sans jamais interroger
  leur activation.
- **F-30 [FAIT NOUVEAU, non vu par le ROADMAP — une TROISIÈME route inerte] :** notre propre
  `docs-flow.md:43-44` documente `--query` (`term`, `status`, `diff`, `refresh`) comme l'un des
  **deux modes normaux** de `gsd-map-codebase`. Or `~/.claude/skills/gsd-map-codebase/SKILL.md:29` :
  « **Requires intel to be enabled in config (`intel.enabled: true`)** ». **Un geste que notre
  documentation publie comme régime courant est inerte aujourd'hui.** A7 n'est donc pas « jamais
  instruit » : il est **déjà promis** par notre doc.
- **F-31 [CONFIRMÉ] :** la frontière `codebase/` ↔ `intel/` est nette et déjà tracée par les
  formats. `.planning/codebase/` = 7 markdown narratifs portant du **jugement humain daté**
  (CONCERNS.md §Tech Debt, §Scaling Limits, §Missing Critical Features ; ARCHITECTURE.md
  §Architectural Constraints), avec des lecteurs **prescrits nommément** (`vf-dev-manager.md:32`,
  `vf-auditer.md:3,23`, `check-dev-bootstrap.sh:27`, `gsd-planner.md:635-653`,
  `scout-codebase.md:8-24`). `.planning/intel/` = 5 **JSON machine** (`stack`, `file-roles`,
  `api-map`, `dependency-graph`, `arch-decisions`) + `API-SURFACE.md`, horodatés et hashés
  (`.last-refresh.json`), avec interdiction explicite du temporel
  (`gsd-intel-updater.md:36,39,269-273`) et **un seul consommateur automatique**, marqué « HINT ONLY
  … MAY BE INCOMPLETE » (`plan-phase.md:754,765-767`).
- **F-32 [CONFIRMÉ] :** `gsd-graphify-update.sh` est posé en `PostToolUse/Bash` dans
  `~/.claude/settings.json` — inerte tant que `graphify.enabled` est `false`, même patron que F-24.

### A9 — workstreams

- **F-33 [PÉRIMÉ — le fait le plus important de tout le re-constat] :** la **PR #27 est CLOSE**
  depuis le **2026-08-03T06:56:32Z** (`state: CLOSED`, `isDraft: true`,
  `reviewDecision: CHANGES_REQUESTED`, `mergedAt: null`, auteur `picmakpro`). Elle n'a pas été
  mergée et n'est plus ouverte. **Le statu quo de fait est aujourd'hui le refus.**
- **F-34 [PÉRIMÉ — la couverture est BIEN PIRE que 18 %] :** re-mesure sur les **91 workflows
  racine** de la 1.9.1 (compte confirmé), en `awk` + `comm` (jamais en `grep` piped) :
  **7 workflows seulement** connaissent les workstreams (5 sur le motif `workstream` insensible à la
  casse — `new-milestone`, `settings`, `settings-advanced`, `settings-integrations`, `transition` —
  plus 2 sur `--ws`), et **45 codent en dur** `.planning/ROADMAP.md`/`STATE.md`/`phases`, dont
  **42 sans aucune conscience des workstreams** (`add-phase`, `execute-phase`, `execute-plan`,
  `next`, `pr-branch`, `plan-phase`, `discuss-phase`, `ship`, `complete-milestone`,
  `extract-learnings`, `quick`, `progress`, `undo`…). **Couverture réelle : 7/91 = 7,7 %**, pas
  18 %. La divergence avec le chiffre du ROADMAP tient à la méthode de comptage, non à une
  régression amont — mais la conclusion s'en trouve durcie, pas adoucie.
- **F-35 [CONFIRMÉ, mécanisme lu ; symptôme NON RE-MESURÉ] :** les trois constats d'outillage
  aveugle tiennent **par lecture du code** — `check-dev-bootstrap.sh:111` cherche
  `"$PLANNING_DIR/ROADMAP.md"` en dur ; `check-state-integrity.sh:53` fixe
  `FILE_REL=".planning/STATE.md"` en dur et porte 6 sorties `exit 2` ; les regex de `pr-branch.md`
  sont ancrées à `^\.planning/(STATE|ROADMAP|MILESTONES|PROJECT|REQUIREMENTS)\.md|^\.planning/milestones/`
  (**`:235-236`**, et non `:232-234` — les lignes ont glissé en 1.9.1), donc
  `.planning/workstreams/dev/STATE.md` ne matche plus `STRUCTURAL` et bascule **transient →
  EXCLUDED**. **Les deux gates sont VERTS aujourd'hui** dans l'arbre non partitionné
  (`check-dev-bootstrap` → « projet complètement cadré — orientation gsd-engine » ;
  `check-state-integrity` → « ✓ conforme »). Le symptôme rouge n'a **pas** été re-mesuré : le
  reproduire exigerait de partitionner `.planning/`, ce que le périmètre de ce nœud interdit.
- **F-36 [CONFIRMÉ] :** le pointeur de workstream ne vit pas dans `.planning/active-workstream` dès
  qu'une clé de session résout, mais dans
  `os.tmpdir()/gsd-workstream-sessions/<sha1(realpath du .planning) tronqué à 16>/<clé>`
  (`active-workstream-store.cjs:98-108`) — **effacé au reboot et indexé sur le chemin absolu, donc
  distinct par worktree et jamais hérité.**
- **F-37 [CONFIRMÉ] :** exactement **3 fichiers** de tout `plugin/` mentionnent « workstream », et
  **tous les trois sont des tables de routage** : `planning-core/references/gsd-handoff.md`,
  `dev-orchestrator/references/gsd-skills-index.md`, `dev-orchestrator/references/intent-routing.md`.
  Aucun agent `vf-*` ne sait passer `--ws`. `vf-dev-manager.md` lit les chemins racine en dur —
  **5 occurrences** (`:30-32`, `:172-173`), pas 7.
- **F-38 [CONFIRMÉ] :** le recouvrement est bien avec **ADR-064** (« un écrivain = un worktree »,
  quick `260801-17w` du 2026-08-01, `.planning/STATE.md:808`), pas avec le moteur. Les deux
  réponses au même problème se composent mal : le pointeur étant indexé sur le chemin du
  `.planning`, chaque worktree ouvre **sans workstream résolu**.

---

## Implementation Decisions

**AUCUNE.** Les 6 zones grises sont instruites dans `24-ARBITRAGES.md` et attendent la réponse de
Samuel. Aucune n'a été tranchée par le worker (`vf-coder` n'a pas d'outil de question — team-kernel :
un worker interne ne parle pas à l'utilisateur). Ce fichier sera complété en `D-01…D-nn` au retour
des arbitrages, **avant** `/gsd-plan-phase 24`.

### Claude's Discretion

Les points suivants relèvent du **plan**, pas de Samuel, et ne remontent pas en arbitrage :
noms de fichiers et de clés ; forme et emplacement des cas de test ; rédaction exacte des lignes de
doctrine ; découpage en plans ; numérotation des ADR ; choix entre étendre un fichier de référence
existant et en créer un (sous réserve de la contrainte ADR-057 « une capacité, une seule voix »).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Arbitrage — à lire EN PREMIER
- `.planning/phases/VFDO-24-activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa/24-ARBITRAGES.md`
  — les 6 zones, leurs options exclusives et les recommandations. **Le plan ne démarre pas avant que
  ses 6 questions aient reçu une réponse.**
- `.planning/phases/VFDO-24-activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa/24-DISCUSSION-LOG.md`
  — trace du cadrage et des faits périmés.

### Périmètre et antériorité
- `.planning/ROADMAP.md` §« Phase 24 » (jusqu'à « ### Phase 25 » exclue) — le périmètre. **Ses faits
  datent du 2026-07-31 et 8 ont péri : lire les F-xx de ce fichier, pas le ROADMAP.**
- `.planning/missions/2026-07-31-mesure-m2-dispatch-parallele.md` — M2, mesuré et arbitré. Ne se
  rediscute pas.
- `.planning/phases/VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-/23-CONTEXT.md`
  — D-01 à D-08 : contrat de checkpoint, `_auto_chain_active`, allowlist stricte de flags, table de
  capabilities **générée** (D-07 : tout index exposé est généré depuis le disque ou gaté).

### Doctrine du module (recouvrements à instruire)
- `plugin/dev-orchestrator/references/mission-contracts.md` §digest (`:51`, `:55-63`) — zone 1.
- `plugin/dev-orchestrator/references/mission-flow.md` §Pattern C (`:136-152`) — zone 4.
- `plugin/dev-orchestrator/references/GSD-PIPELINE.md` (`:188-199`) — voie unique — zone 4.
- `plugin/dev-orchestrator/references/docs-flow.md` (`:39-46`) — famille code, mode `--query` — zone 3.
- `plugin/dev-orchestrator/references/gsd-capabilities-index.md` — table générée (Phase 23) — zone 3.
- `plugin/dev-orchestrator/references/intent-routing.md` (`:104`, `:147`) — zone 3.
- `plugin/software-architecture/references/principles.md` (`:52-72`) — carte TDD — zone 1.
- `plugin/software-architecture/rules/production-code-architecture.md` (`:2-11`) — path-scope dormant.
- `.planning/quick/260801-17w-isolation-multi-session/SUMMARY.md` — **ADR-064** — zone 5.
- `CLAUDE.md` — conventions de commit et de release — zone 2.

### Moteur (source de vérité machine, gsd-core 1.9.1)
- `~/.claude/gsd-core/bin/lib/capability-registry.cjs` — 44 capabilities, 12 points, config par clé.
- `~/.claude/gsd-core/bin/lib/init.cjs` (`:1731-1815`) — `buildAgentSkillsBlock`, 17 slots.
- `~/.claude/gsd-core/bin/lib/host-integration.cjs` (`:464`) — `shouldFlattenDispatch`.
- `~/.claude/gsd-core/bin/lib/active-workstream-store.cjs` (`:98-108`) — pointeur de workstream.
- `~/.claude/gsd-core/workflows/execute-phase.md` (`:28-31`, `:86`, `:693`, `:715`) — injection et repli.
- `~/.claude/gsd-core/workflows/execute-plan.md` (`:94`, `:100`) — seuil inline.
- `~/.claude/gsd-core/workflows/pr-branch.md` (`:235-236`) — regex de classification.
- `~/.claude/gsd-core/references/planning-config.md` (`:41`, `:241`, `:276`) — schéma des clés.
- `~/.claude/gsd-core/contexts/dev.md|review.md|research.md` — les 3 profils **sans consommateur**.
- `~/.claude/skills/gsd-map-codebase/SKILL.md` (`:29`) — dépendance `--query` → `intel.enabled`.

### Gates de ce dépôt
- `plugin/conductor/scripts/check-agents.sh` (`:514-516`) — validation `effort:`.
- `plugin/conductor/scripts/check-state-integrity.sh` (`:53`) — chemin `STATE.md` en dur.
- `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` (`:111`) — chemin `ROADMAP.md` en dur.
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (`:1289-1321`, T14) — exhaustivité
  du routage, aveugle à l'activation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Barème d'effort déjà écrit** : les 3 agents-templates de
  `plugin/reference/content/methodology/templates/agents/` portent `effort: medium|high` (F-07). Le
  plan de M3 propage un barème existant, il n'en invente pas un.
- **Générateur d'index** : le patron `build-gsd-index.sh` → `gsd-skills-index.md` (D-07 de la
  Phase 23) est le modèle imposé pour toute table exposée. `gsd-capabilities-index.md` en est déjà
  issu — l'étendre à `graphify`/`profile-pipeline` (F-29) suit la même mécanique.
- **Auto-gating des hooks amont** : `gsd-validate-commit.sh` et `gsd-workflow-guard.js` lisent
  eux-mêmes `.planning/config.json` (F-24) — aucune plomberie de hook à écrire, seulement une clé.

### Established Patterns
- **Tout index exposé est généré depuis le disque ou gaté** (D-07, Phase 23). Interdit : une table
  d'activation écrite à la main.
- **ADR-030 : on délègue, on n'absorbe pas.** Interdit de forker un mécanisme GSD — ce qui ferme
  d'emblée toute réécriture locale des profils de contexte ou du seuil inline.
- **ADR-031 : jamais de fix sans validation humaine.** Les hooks du module sont *advisory* —
  `hooks.json` de `dev-orchestrator` le dit explicitement (« chaque signal propose un geste, aucun
  ne l'exécute »). Un gate bloquant (zone 2) rompt ce patron et doit être justifié comme exception.
- **ADR-029 : densité** (agents ≤ 250 l., skills ≤ 500). `mission-contracts.md` est déjà à 21,2 K —
  toute doctrine nouvelle doit choisir son fichier, pas s'y ajouter par défaut.

### Integration Points
- `.planning/config.json` — **le point d'intégration principal** : 9 des 11 items se règlent par une
  clé. Il est surveillé par `check-gsd-config.sh` (advisory, `SessionStart`) et par le hook amont
  `FileChanged/config.json → gsd-config-reload.js`.
- `test-dev-orchestrator.sh` — toute décision d'activation doit y produire un cas, sinon le trou se
  rouvre au prochain skill ajouté (F-29).
- `~/.claude/settings.json` — **ne pas y toucher** : les hooks concernés y sont déjà posés (F-24,
  F-32) et ce fichier est hors du dépôt.

</code_context>

<specifics>
## Specific Ideas

- **Le lot MESURE avant le lot ACTIVATION** est un ordre imposé par le ROADMAP, pas une préférence :
  M2 devait être connu avant d'activer quoi que ce soit. Il l'est. M1 et M3 (zone 6) doivent être
  traités avant les zones 1 à 5 dans l'ordre des plans.
- **Trois routes inertes, pas deux** : le ROADMAP en connaissait deux (A8) ; le cadrage en a trouvé
  une troisième, et c'est la plus gênante parce que c'est **notre propre documentation** qui promet
  le geste (F-30). Le motif est le même à chaque fois — une entrée de doc ou de routage qui survit à
  une capability éteinte, sans gate pour le dire.
- **Deux faits invalident des prémisses du ROADMAP et doivent être corrigés au plan** : « un gate de
  commit existe » (F-25, faux) et « le moteur porte les profils de contexte en config » (F-20, il ne
  les porte pas — il les déclare). Le ROADMAP §Phase 24 devra être recalé en fin de phase, comme
  l'ont été les §Phase 20 et §Phase 21.

</specifics>

<deferred>
## Deferred Ideas

- **Corriger le ROADMAP §Phase 24 lui-même** (8 faits périmés en 4 jours) — appartient à la
  gouvernance de fin de phase, pas au cadrage. À faire au dernier plan de la 24.
- **Remontée upstream à `@opengsd/gsd-core`** des 42 workflows aveugles aux workstreams, et des
  3 profils de contexte sans consommateur — même famille que la voie 2 de M2 (déjà retenue) et que
  la RFC de la Phase 18. Ce sont des **gestes de contribution externe**, pas du code de ce dépôt :
  ils se planifient mais ne se livrent pas ici.
- **Fenêtre WINDOWS #3** (recette XcodeBuildMCP sur lab iOS équipé) — non fermable dans ce dépôt.
  Sa résolution appartient à un lab iOS, pas à la Phase 24.
- **Portée de `production-code-architecture`** (F-16 : path-scope `src|app|lib|features` inexistant
  ici) — c'est un défaut du module `software-architecture`, hors des 11 items. À porter au backlog.
- **Phase 25** (budget d'instructions, étage d'alignement court) — frontière explicite, ne pas
  déborder.

</deferred>

---

*Phase: 24-Activation et mesure du moteur GSD — capacités dormantes et faits de runtime*
*Context gathered: 2026-08-04*
