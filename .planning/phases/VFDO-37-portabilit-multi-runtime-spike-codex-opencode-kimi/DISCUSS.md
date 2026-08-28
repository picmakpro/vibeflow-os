# DISCUSS — Phase 37 : portabilité multi-runtime (spike de mesure)

Milestone `fiabilite-v1.0`. Procès-verbal de cadrage — les 6 questions du ROADMAP (§~976-1050)
ont toutes reçu une réponse **mesurée**. Ce document n'est pas un questionnaire : c'est le
constat, question par question, ce qu'il implique, et ce qui reste ouvert.

## Q1 — API runtime de gsd-core

| | |
|---|---|
| **Réponse mesurée** | Les convertisseurs sont purs, chargeables par `require()`, exécutés avec succès. Mais `bin/lib/host-integration-sdk.cjs` porte la seule frontière public/interne écrite de `bin/` : « the published public surface … External host-plugin authors import ONLY from this entry. It IS the contract … everything else in gsd-core is internal. » SDK gelé, `PROTOCOL_VERSION` 1, 18 clés ; filtre `/convert\|artifact\|layout\|installPlan\|Skill/i` sur ces clés → tableau vide. Les 8 modules visés sont internes par contrat écrit, sans engagement SemVer. **Nuance** : le SDK public déclare `artifact` parmi ses 6 points d'interface, et `degradationFor('artifact', axes)` répond — les helpers de conversion, eux, ne sont pas exportés ; l'argument « surface interne » est donc plus fermé qu'il n'y paraît à la seule lecture du filtre de clés, ce qui renforce la voie « démarche amont » (voie 2, cf. §Décision à prendre). |
| **Preuve** | Lecture directe de `host-integration-sdk.cjs` (commentaire de tête) + filtre exécuté sur ses clés exportées → 0 résultat. `package.json` sans champ `exports`. `createRuntimeArtifactInstallPlan` testé sur un arbre tiers : `ok: true`, 0 skill tiers staged, 49 agents ramassés dans `~/.claude/agents`. |
| **Conséquence** | Le pipeline d'install n'est pas générique — il résout sa source par remontée `__dirname` vers `commands/gsd` de gsd-core, pas via un point d'entrée public. L'échappatoire `.gsd-source` a deux consommateurs aux sémantiques incompatibles (non résolu par ce spike). |

## Q2 — Ce qui est spécifiquement VibeFlow

| | |
|---|---|
| **Réponse mesurée** | 31 agents posés (25 `plugin/*/agents/*.md` + 6 `AGENT.md`), 3 619 lignes, dont 19 `vf-internal: true` et **9** avec allowlist `Agent(...)`. 6 fragments `hooks.json`. 3 fichiers de packaging. « 8 scripts sur 65 couplés au bus de hooks » — **non reproductible, méthode d'origine non consignée** (retiré, cf. Preuve). |
| **Preuve** | Comptage direct sur l'arbre `plugin/`. **Correction (tour 3)** : le décompte scripts/blueprints du tour précédent n'était pas re-dérivable. Re-mesuré : `find plugin -iname "*.sh" \| wc -l` → **136** scripts `.sh` sous `plugin/` ; `find plugin -path "*/scripts/*.sh" \| grep -v 'reference/content' \| wc -l` → **123** sous un `*/scripts/` hors `reference/content` ; `find plugin -iname "*.blueprint.md" \| wc -l` → **9** blueprints. Ni le dénominateur « 65 », ni « 57 scripts neutres », ni « 24 blueprints » ne se reconstituent depuis ces commandes — périmètre ou date de mesure différents, non retrouvés. |
| **Conséquence** | Le périmètre spécifique VibeFlow est petit et localisé (agents + hooks + packaging). Le chiffrage exact des scripts/blueprints « neutres » n'est **pas utilisé par le SPIKE** et reste non reproductible — ne pas le citer comme argument tant qu'une méthode n'est pas consignée. |

## Q3 — SKILL.md

| | |
|---|---|
| **Réponse mesurée** | 25 fichiers dont 21 installables (4 gabarits sous `plugin/reference/content/`). 3 ont `name` ≠ dossier. **8** (méthode : `grep -rlE 'gsd-[a-z-]+' --include=SKILL.md plugin/` — fichiers citant un skill `gsd-` **nommé**. Un 9ᵉ fichier, `vf-dev/SKILL.md`, mentionne la famille `gsd-*` génériquement sans nommer de skill : il compte sous un motif large, pas sous la définition « appelle »). 8 portent un dispatch explicite, 13 mentionnent un agent — **non reproductible, méthode d'origine non consignée** (cf. Q2). 3 utilisent `AskUserQuestion`. **Correction (tour 3, majeur) : 15 des 21 skills installables perdent `description:` en entier à la conversion, sur les trois cibles** — écrite verbatim comme le littéral `>` (ex. `plugin/planning-core/SKILL.md:3`). |
| **Preuve** | Inspection frontmatter des 25 fichiers + grep sur `gsd-*`, dispatch, mention d'agent, `AskUserQuestion`. Description : `grep -lE '^description:\s*>' <21 skills>` → 15 fichiers. Cause : `extractFrontmatterField` (`runtime-artifact-conversion.cjs:924-930`) lit la frontmatter avec une regex mono-ligne `^description:\s*(.+)$`, incompatible avec le scalaire replié YAML `description: >` (texte sur les lignes suivantes). Vérifié en exécutant `convertClaudeCommandToOpencodeSkill`, `convertClaudeCommandToKimiCodeSkill` et `convertClaudeCommandToCodexSkill` sur `plugin/planning-core/SKILL.md` : les trois écrivent `description: >`. |
| **Conséquence** | Piège structurel : `install_module()` pose le skill sous le nom du **module**, pas sous le `name` du frontmatter. Un runtime à surface `slash-file` dérive le nom depuis le **chemin** → les 3 skills à `name` ≠ dossier y seraient invoqués sous le mauvais nom. Correction requise avant toute cible dont le nommage suit le chemin. **Et** : la description est ce qui rend un skill déclenchable — sa perte silencieuse sur 15/21 skills est une dégradation au moins aussi large que celle mesurée côté agents, à couvrir par le même gate de fidélité. |

## Q4 — L'équipe de mission hors Claude (mesuré en exécution réelle, Codex CLI 0.150.1, compte ChatGPT)

| | |
|---|---|
| **Réponse mesurée** | Profondeur réelle = **3 arêtes** (compteur natif `session_meta`, `DEPTH=1/2/3`, chemins `/root/lvl_one/lvl_two/lvl_three`, chaque niveau écrivant son fichier). Le `maxDepth: 1` du registre gsd-core est **faux** — le prompt developer des sous-agents dit lui-même qu'ils peuvent essaimer. Le no-go structurel envisagé tombe. La vraie contrainte est la **largeur** : 4 slots de concurrence disponibles → 3 workers concurrents max sous un manager. `agent_name` doit matcher `[a-z0-9_]+` (erreur runtime verbatim) → `vf-dev-manager`, `vf-coder`, `vf-design-judge` rejetés tels quels, mapping de noms requis. `--ephemeral` casse le spawn (`collab spawn failed: no thread with id`) — le mode collaboration exige un thread persisté. `report_agent_job_result` a disparu en 0.150.1 (présent au tag `rust-v0.128.0`) ; la boîte actuelle est `spawn_agent / send_message / followup_task / wait_agent / interrupt_agent / list_agents`, `wait_agent` rend `{message, timed_out}` — enveloppe typée à charge utile texte libre. Le rapport typé `{statut, findings, noeuds_debloques}` est reconstructible par convention (JSON dans le cwd partagé) et fiable 2/2 ; `codex exec --output-schema` le rend directement conforme. Modèle par worker : **oui, mesuré** (`gpt-5.6-terra` root, `gpt-5.4-mini`/`gpt-5.6-luna` workers) via `fork_turns: "none"` + `model` ; `hide_spawn_agent_metadata` pas nécessaire. Contrepartie : `fork_turns: "none"` = zéro contexte hérité, tout le digest doit passer dans le task text. Régression `#27331` **non reproduite** : tour trivial `codex exec --enable multi_agent_v2` → `EXIT=0`, aucune 400. |
| **Preuve** | Exécution réelle sur compte ChatGPT, sorties runtime citées verbatim (erreurs, `session_meta`, prompt developer). |
| **Conséquence** | Profondeur suffisante pour l'équipe VibeFlow (manager → coder/reviewer, 2 arêtes utilisées). Largeur = budget à respecter (3 concurrents). Mapping de noms + `fork_turns`/digest complet = travail d'adaptateur nécessaire, pas structurel bloquant. |
| **Non mesuré** | Profondeur > 3, saturation des 4 slots, rôles custom `~/.codex/agents/*.toml` (non utilisés, `agent_role` resté `null`). |

## Q4b — L'escalade humaine

| | |
|---|---|
| **Réponse mesurée** | La prémisse ROADMAP (« aucun équivalent hors Claude ») est **fausse** : Codex a `request_user_input`, OpenCode a `question`, Kimi / Kimi Code a `AskUserQuestion` — quasi isomorphes. **Existence des outils, contrat fail-loud et comportement d'`opencode run --auto` : dérivés de la documentation et des issues amont, non vérifiés en runtime.** Codex mesuré (compte ChatGPT, Codex CLI 0.150.1) ; OpenCode et Kimi / Kimi Code documentaires, **produit non désambiguïsé** (cf. avertissement ROADMAP l. 1011-1012 : Kimi et Kimi Code sont deux produits distincts). Le vrai trou est le **mode headless**, universel. Codex : barré deux fois en dur (`request_user_input can only be used by the root thread`, rejeté sous `codex exec`) ; l'élicitation MCP y est auto-annulée (ni refus ni accord). OpenCode : l'outil `question` **pendrait** en headless, et le correctif en cours **viserait** à le faire **échouer**, pas à répondre — **dérivé de la documentation et de l'issue amont, non vérifié en runtime : OpenCode n'est pas installé sur le poste de mesure** (cf. Preuve : OpenCode #35275). Kimi / Kimi Code : seul contrat fail-loud écrit (« a failure message is returned ») **(produit non désambiguïsé, non vérifié en runtime)**. Danger identifié : `opencode run --auto` approuve automatiquement ce qui n'est pas explicitement refusé — à interdire formellement. |
| **Preuve** | Comportements runtime cités verbatim + design amont déjà écrit (OpenCode #35275 citant Codex : suspendre l'horloge plutôt qu'arbitrer un timeout ; Codex a déprécié `autoResolutionMs` au profit d'`isBlocking`). |
| **Conséquence** | Ne jamais autoriser une question **dans** un worker headless ; la relayer hors bande vers une session racine vivante — c'est exactement le relais `SendMessage`/Pattern H que VibeFlow possède déjà (cf. mémoire `askuserquestion-absent-en-subagent`). Pas de nouveau mécanisme à construire, un pattern existant à étendre. |

## Q5 — Déclaration de capacité

| | |
|---|---|
| **Réponse mesurée** | N'existe nulle part dans VibeFlow : les 17 `module.json` ne portent que `{name, version, type, description, requires}` (+ `mandatory`, `proposable`). `grep skills-only` et `grep unsupported` → 0 hit. `type` est un faux ami (prose libre, 12 formes pour 17 modules). gsd-core porte déjà un modèle à **10 axes** (`HOST_INTEGRATION_AXES` : embeddingMode, commandSurface, modelMode, hookBus, stateIO, transport, runtime, subagentToolkit, effortSurface, isolation), 6 points d'interface, 3 profils et `degradationFor(point, axes)`. |
| **Preuve** | Grep exhaustif sur les 17 `module.json` + lecture du modèle de capacité gsd-core. |
| **Conséquence** | Un enum maison `full\|skills-only\|unsupported` réimplémenterait, en le dégradant, ce que le moteur calcule déjà — interdit par la doctrine de la phase. **Mais** cette seule mission a produit 3 constats de non-fiabilité autour des descripteurs consultés (2 sur codex, 1 sur kimi-code), de nature différente : `maxDepth: 1` **faux, erreur du registre vérifiée en exécution** ; `backgroundDispatch` — le registre avait raison (`codex: true`), c'est la **lecture du cadrage** qui l'avait inversé ; descripteur `kimi-code` **périmé**, constat par lecture documentaire, **jamais vérifié en runtime** (kimi-code non installé). Bonne **source**, jamais une **preuve** — toute dépendance dessus doit prévoir une vérification runtime, pas une lecture statique du registre. |

## Q6 — `vibeflow-update.sh`

| | |
|---|---|
| **Réponse mesurée** | 2 232 lignes. `TARGET_ROOT` a un seul site de calcul (l. 105-109), jamais réassigné. `VF_TARGET_ROOT` est déjà la convention côté `generate-agent-commands.sh` (l. 23) mais l'engine ne la lit pas. |
| **Preuve** | Lecture directe des deux scripts, grep des littéraux `.claude`. |
| **Conséquence** | Couture minimale : rendre le site de calcul injectable + paramétrer les littéraux `.claude` — **16 sites, 15 littéraux distincts** (14 dans `gitignore_add_paths`, 2 dans `scripts_prefix_for_scope` ; `.claude/agents/${mod}-references/` apparaît deux fois, d'où l'écart site/littéral). Le reste se fait hors engine, via `merge-hooks.sh` (déjà externe, CLI stable) et les 2 helpers `vf_place_file`/`vf_place_tree`. **Ne pas** ajouter un `--target` orthogonal à `--scope` : recouvrement fonctionnel, réécriture d'`install_module` à la clé — hors budget du spike. |

## Fidélité de conversion — la dégradation silencieuse, chiffrée

156 conversions mesurées (31 agents + 21 skills × 3 cibles) : **0 exception, 0 retour nul, 0
diagnostic**. Pertes constatées :

| Élément | Perte |
|---|---|
| `model:` | 31/31 **sur codex et opencode** (la kind `agents` de kimi-code déclare `converter: null`, mais le pipeline d'install applique tout de même 4 étapes transverses — 6/31 fichiers modifiés ; le champ y est néanmoins conservé, rejoué via `stageAgentsForRuntimeWithConverter`) |
| `memory:` | 31/31 **sur codex et opencode**, par le même raisonnement (conservé sur kimi-code) |
| `tools:` | 25/25 **sur codex et opencode**, idem |
| `disallowedTools:` | 6/6 **sur codex et opencode**, idem |
| `vf-internal:` | 19/19 sur codex ; **0/19 sur opencode et kimi-code (conservé)** — rejoué |
| Allowlist `Agent(...)` | devient prose dans `<codex_agent_role>` sur codex ; purement supprimée sur opencode → un juge conçu pour ne pas écrire (`vf-design-judge`) y perdrait son interdiction — **selon le descripteur opencode, non vérifié en runtime : opencode n'est pas installé sur le poste de mesure** |
| Bloc adaptateur | couvre 21/21 skills et **0/31 agents** — or ce sont les agents qui portent les protocoles |
| `description:` (skills) | **perdue en entier sur 15/21 skills installables, sur les trois cibles** — `extractFrontmatterField` (regex mono-ligne) ne gère pas le scalaire replié YAML `description: >`, écrit verbatim le littéral `>` — **vérifié en exécutant les trois convertisseurs réels** sur `plugin/planning-core/SKILL.md` |
| `Task(` | non traduit — **rejoué en exécutant les convertisseurs réels sur les 52 artefacts** : 3 fichiers / 5 occurrences, identique sur opencode et kimi-code |
| Chemins `.claude` | morts — **rejoué via la séquence d'install réelle** (`stageAgentsForRuntimeWithConverter`), pas les convertisseurs isolés — c'est cette distinction qui produisait l'écart : 25/52 fichiers sur opencode (150 occurrences), 25/52 fichiers sur kimi-code (157 occurrences). « fichiers » ≠ « occurrences » : ne pas confondre les deux dénominateurs. Le plafond 52/52 est impossible : seuls 26/52 fichiers source contiennent `.claude` avant conversion |
| Agents sur kimi-code | 31 agents posés avec `converter: null` — 6/31 modifiés par les 4 étapes transverses du pipeline d'install, champs conservés — dans un runtime dont le descripteur porte `namedDispatch: false` → 52 fichiers posés, dont potentiellement 31 inertes **selon ce descripteur — que ce même document déclare par ailleurs périmé (cf. tableau de corrections ci-dessous) ; si kimi-code dispatche bien des sous-agents nommés custom comme sa doc courante le décrit, ces 31 agents ne sont pas inertes** |

**Conséquence directe** : la garantie ADR-044 (« agents natifs machine-enforced ») ne survit **ni à
codex ni à opencode** (les deux seules cibles où la kind `agents` passe par un convertisseur qui
réécrit `model`/`memory`/`tools`/`disallowedTools`/allowlist — `vf-internal` étant, lui, perdu sur
codex seulement, conservé sur opencode et kimi-code) — **aucun champ n'y est
perdu à la conversion sur kimi-code** (dont l'entrée `agents` du registre porte `converter: null`,
mais 6/31 fichiers sont tout de même modifiés par les 4 étapes transverses du pipeline d'install,
sans perte de champ, cf. ligne « Agents sur kimi-code » ci-dessus). Que kimi-code **honore** ces
champs n'a pas été vérifié — runtime non installé.

**Placement manuel** : **13 règles** pour les 3 runtimes — relevé direct de
`artifactLayout.global.length + artifactLayout.local.length` dans `capability-registry.cjs`
(codex 4, opencode 6, kimi-code 3), pas 21. Codex a deux homes distincts pour ses 4 règles :
`~/.agents/skills/` et `~/.codex/agents/`. Les 6 fragments de hooks n'ont aucun convertisseur
utilisable (`buildCodexHookBlock` câblé en dur sur les scripts de gsd-core) ; opencode déclare
`hooksSurface: 'none'` → les 6 sont perdus par construction **(dérivé du descripteur, non vérifié
en runtime — opencode n'est pas installé sur le poste de mesure)**.

## Corrections au cadrage ROADMAP

| Cadrage ROADMAP | Correction mesurée |
|---|---|
| « 50 agents » | **31** |
| « 13 runtimes » | **19** ; et `runtime-aliases.manifest.json` n'est pas la table de capacités — c'est `capability-registry.cjs` |
| « 9/25 gsd-* » | **8** (méthode : `grep -rlE 'gsd-[a-z-]+' --include=SKILL.md plugin/` — fichiers citant un skill `gsd-` **nommé**. Un 9ᵉ fichier, `vf-dev/SKILL.md`, mentionne la famille `gsd-*` génériquement sans nommer de skill : il compte sous un motif large, pas sous la définition « appelle ») |
| « 9/25 sous-agents » | **8** dispatch / 13 mention — **non reproductible, méthode d'origine non consignée** |
| « MultiAgentV2 v0.128.0 » | courant **0.150.1** |
| « built-ins default/worker/explorer/monitor » | **3** (`default`, `worker`, `explorer`) — `monitor` n'existe pas, un `awaiter` est présent mais commenté |
| « `backgroundDispatch: false` sur codex » | c'est la ligne de **claude** ; codex vaut `true`, opencode a `background: false` |
| `#14579` et `#31814` | **fermées** ; `#31814` mal décrite (mécanisme réel : `hide_spawn_agent_metadata` à `true` par défaut) |
| Descripteur `kimi-code` de gsd-core | **périmé** — kimi-code a désormais des sous-agents nommés custom, `AgentSwarm` à rapport agrégé, pool de modèles |

## Décision à prendre (non tranchée — ADR-031)

La doctrine de la phase (« VibeFlow consomme la surface gsd-core, il ne la réimplémente pas »)
se heurte à trois faits mesurés : la surface visée est **déclarée interne** (Q1), son pipeline
d'install **n'est pas générique** (Q1), et son registre de capacités s'est montré, sur cette seule
mission, une source à vérifier avant usage — une erreur avérée en exécution (`maxDepth`), une
mauvaise lecture du cadrage qui l'accusait à tort (`backgroundDispatch`), et une obsolescence
documentaire jamais confrontée au runtime (`kimi-code`) (Q5). Pendant ce temps le runtime Codex,
lui, est **plus capable que son descripteur** ne le dit (Q4 : profondeur réelle 3, pas 1).

Voies possibles, coûts exposés, aucune tranchée ici :

1. **Dépendre de l'interne tel quel** — coût : zéro garantie SemVer, rupture possible à chaque
   mise à jour de gsd-core sans préavis ; nécessite une détection de dérive (tests de contrat).
2. **Demander l'élargissement du SDK public en amont** (upstream gsd-core) — coût : délai hors
   contrôle de VibeFlow, dépendance à la réactivité du mainteneur ; bénéfice : solution durable si
   elle aboutit.
3. **Adaptateur VibeFlow minimal** — coût : maintenance d'une couche de conversion propre
   (au minimum : préserver `model`/`memory`/`tools`/`disallowedTools`/`vf-internal`/allowlist sur
   les 31 agents, corriger le nommage `name` ≠ dossier sur les 3 skills concernés, mapper les noms
   d'agents vers `[a-z0-9_]+` sur codex) ; bénéfice : garanties ADR-044 restaurées, sous contrôle
   VibeFlow.
4. **Renoncer** (rester Claude-only) — coût : aucune portabilité multi-runtime ; bénéfice :
   zéro dette de maintenance supplémentaire, cohérent avec l'état actuel du repo.

Arbitrage humain requis (ADR-031) — ce document n'en tranche aucune.
