# Dépendances GSD et superpowers : peut-on les internaliser ?

Mission en lecture seule, menée le 2026-10-29. Base mesurée : `origin/main` = `3656698b` (merge PR #173).
Poste : gsd-core **1.19.0** (`~/.claude/gsd-core/VERSION`), superpowers **7.0.0** en scope user. Deux
autres versions de superpowers sont présentes en scope project : 5.0.7 et 5.1.0.

> **Pièges de mesure rencontrés**
> - Sur ce poste, `find` et `ls` sont des fonctions shell : elles renvoyaient 0 ligne ou un format
>   enrichi. Tous les comptages ci-dessous passent par `/usr/bin/find`, `/bin/ls -1` ou un script
>   Python de comptage par extension (`scratchpad/tools/loc.py`).
> - `git grep` et `wc` passent par `rtk proxy`.
> - Les comptages de lignes visent des **fichiers entiers**. Ils ne disent pas quelle part de chaque
>   fichier dépend de GSD.

---

## 1. Surface de dépendance (origin/main)

### 1.1 Fichiers qui citent les deux frameworks

```
for p in 'gsd-' 'gsd-core' 'gsd-tools' 'superpowers:' 'superpowers'; do for d in plugin scripts; do
  rtk proxy git grep -l -F -e "$p" origin/main -- $d | wc -l; done; done
```

| motif | plugin/ (557 fichiers) | scripts/ (32 fichiers) |
|---|---|---|
| `gsd-` | **137** (24,6 %) | 4 |
| `gsd-core` | 68 | 4 |
| `gsd-tools` | 21 | 0 |
| `superpowers:` | **10** | 0 |
| `superpowers` (tout usage) | 33 | 1 |

Une partie des 33 fichiers « superpowers » ne vise pas le plugin : ils citent le chemin homonyme
`docs/superpowers/{specs,plans}`.

Côté GSD, `git grep -o 'gsd-[a-z][a-z0-9-]+'` donne 575 occurrences de `gsd-core`, 135 de
`gsd-tools`, 147 de `gsd-engine`, etc. Cette liste brute mélange les noms de skills et d'agents
avec des noms de scripts et des fixtures de test (`gsd-jamais-cree`, `gsd-mystere`…). Elle est
conservée dans `scratchpad/gsd-names.txt`.

### 1.2 Skills et agents GSD appelés par VibeFlow

Méthode : on croise les noms installés (`@opengsd/gsd-core/skills/*`, `agents/*.md` hors
`.compact`) avec les citations de `plugin/` et `scripts/`. Sont exclus de ce croisement les
dossiers `*/tests/*`, les `CHANGELOG.md`, `gsd-capabilities-index.md`, `gsd-skills-index*` et
`GSD-PIPELINE.md`. Le tableau complet (nom → nombre de fichiers appelants → fichiers) est dans
`scratchpad/usage-table.txt`.

- **Skills : 72 sur 72 sont nommés**, mais pour des raisons très différentes :
  - **32** n'apparaissent que dans `dev-orchestrator/references/intent-routing.md`. C'est la
    table de routage, qui recopie le catalogue entier. Ce sont des renvois et non des usages
    câblés : `gsd-ns-*`, `gsd-thread`, `gsd-stats`, `gsd-help`, `gsd-ultraplan-phase`, etc.
  - **29** sont cités dans 3 fichiers ou plus. C'est le **cœur réel**. En tête :
    - `gsd-discuss-phase` (11 fichiers) ;
    - `gsd-plan-phase` (10) et `gsd-execute-phase` (10) ;
    - `gsd-new-project` (9) ;
    - `gsd-map-codebase` (8) et `gsd-import` (8) ;
    - `gsd-verify-work` (7) et `gsd-ingest-docs` (7) ;
    - `gsd-quick` (6), `gsd-progress` (6) et `gsd-docs-update` (6) ;
    - `gsd-config`, `gsd-sketch`, `gsd-new-milestone`, `gsd-explore`, `gsd-debug`,
      `gsd-complete-milestone`, `gsd-ui-review`, `gsd-spike`, `gsd-graphify`,
      `gsd-extract-learnings`, `gsd-autonomous`, `gsd-ui-phase`, `gsd-ship`, `gsd-review`,
      `gsd-mempalace-capture`, `gsd-code-review`, `gsd-cleanup`, `gsd-audit-milestone`.
- **Agents : 27 sur 35 sont nommés.** Les mêmes noms, 26 réels plus la fixture
  `gsd-jamais-cree`, figurent dans les **listes blanches `Agent(...)` du frontmatter** des agents
  VibeFlow : `vf-coder`, `vf-dev-manager`, `vf-reviewer`, `vf-auditer` et `vf-design-manager`.
  C'est un **couplage dur** : si l'agent cible manque, le dispatch échoue.
  - Les plus cités : `gsd-executor` (6 fichiers), `gsd-planner` (5), `gsd-code-reviewer` (4),
    `gsd-plan-checker` (4), `gsd-phase-researcher` (3).
  - Les 8 agents jamais cités : `gsd-user-profiler`, `gsd-research-synthesizer`,
    `gsd-project-researcher`, `gsd-mempalace-curator`, `gsd-intel-updater`, `gsd-eval-auditor`,
    `gsd-dom-verifier`, `gsd-debug-session-manager`.

### 1.3 Skills superpowers appelés par VibeFlow

`rtk proxy git grep -h -o -E 'superpowers:[a-z-]+' origin/main -- plugin scripts | sort | uniq -c`

| skill | occurrences | nature |
|---|---|---|
| `writing-skills` | 8 | **frontière** ADR-057 avec skill-creator (`AGENT.md`, `README.md`, `check-overlaps.sh`). On ne délègue pas à ce skill. |
| `brainstorming` | 4 | routage : `intent-routing.md:56`, `design-toolchain.md:18`, `design-vocabulary-map.md`, `check-overlaps.sh` |
| `test-driven-development` | 2 | routage |
| `systematic-debugging` | 2 | frontière avec `gsd-debug` (ADR-057) |
| `verification-before-completion` | 1 (+20 fichiers avec le nom nu) | gate dans `design-toolchain.md:19`. Le nom nu revient surtout dans des blueprints de bundles (`scriptwriter.blueprint.md`), qui le listent dans `skills:`. |
| `requesting-code-review` | 1 | frontière (ADR-057) |

Les noms `writing-plans`, `subagent-driven-development`, `using-git-worktrees`, `executing-plans`,
`receiving-code-review`, `dispatching-parallel-agents` et `finishing-a-development-branch` ne sont
cités dans aucun fichier de `plugin/` (tests et CHANGELOG exclus).

La mémoire `agent-skills-ecarte-superpowers-reste.md` disait « 4-5 skills câblées (brainstorming,
writing-skills, subagent-driven-development, worktrees) », puis « 3 skills réellement invoqués ».
La seconde formulation est la bonne : sur `origin/main`, ni `subagent-driven-development` ni
`using-git-worktrees` ne sont cités.

**Ce qui fait de superpowers une dépendance dure, c'est l'installeur, pas les appels.**
`design-orchestrator/scripts/ensure-design-deps.sh:52,322` refuse son exclusion (« dépendance dure
de VibeFlow ») et `dev-orchestrator/scripts/ensure-deps.sh:8` l'installe.

### 1.4 Ce qui casse sans GSD (mécanismes durs) et ce qui se remplace

**Ce qui casse, ou devient non vérifiable :**

1. **Scripts qui exécutent la CLI `gsd-tools`.** Ils résolvent tous le moteur par une cascade :
   `GSD_TOOLS`, puis `PATH`, puis `~/.claude/gsd-core/bin/gsd-tools.cjs`.
   - `dev-orchestrator/scripts/gsd-run.sh` (81 l) : le lanceur appelé par les agents.
   - `conductor/scripts/split-planning.sh` (302 l) : sans moteur, il s'arrête avec « aucune
     écriture ».
   - `conductor/scripts/check-planning-not-inflight.sh` (147 l) : sans moteur, il rend
     NON-VÉRIFIABLE.
   - `conductor/scripts/dag.sh` (514 l) : appelle `claude-orchestration emit-workflow` et se
     replie sur `ready`/`count` seuls (ADR-069).
2. **Scripts qui lisent les fichiers internes du moteur comme du texte.**
   - `check-gsd-config.sh` (749 l, lit le schéma de config).
   - `build-gsd-capabilities-index.sh` (lit `capability-registry.cjs`).
   - `check-gsd-engine.sh`, `planning-core/scripts/detect-gsd-engine.sh` et
     `scripts/check-gsd-core-update.sh`.
   - `ensure-deps.sh` (830 l) : installe le moteur par `npx @opengsd/gsd-core@^1` et Node ≥ 24.
3. **CI** (`.github/workflows/ci.yml`).
   - L'étape « Installer le moteur GSD » lance `npx -y "@opengsd/gsd-core@^1" --claude --global`.
   - Deux **canaris de forme du moteur** suivent : `check-gsd-config.sh` et le générateur
     d'index.
   - Le gate T28-F compare l'index versionné à celui qu'on régénère.
   - Plusieurs étapes posent des fixtures `gsd_state_version: 1.0` et `GSD_WORKSTREAM`.
4. **Hooks.**
   - `dev-orchestrator/hooks/hooks.json` appelle `check-gsd-config.sh --hook`.
   - `planning-core/hooks/hooks.json` tourne en `--defer-to-gsd`.
   - Le moteur pose lui-même **18 scripts de hook distincts** dans `~/.claude/settings.json` :
     `gsd-context-monitor` ×4, `gsd-workflow-guard`, `gsd-prompt-guard`, `gsd-read-guard`,
     `gsd-write-guard`, `gsd-worktree-path-guard`, `gsd-agent-isolation-guard`,
     `gsd-validate-commit`, `gsd-session-state`, `gsd-statusline`, etc. Ce sont des garde-fous
     dont VibeFlow profite sans les posséder.
5. **Listes blanches `Agent(...)`** de 5 agents VibeFlow, qui nomment 26 agents gsd-*.
6. **Format `.planning/`** (détail au §1.5).

En tout, **46 scripts `.sh` hors tests** citent `gsd` (25 618 lignes de fichiers entiers ; la
part GSD n'est pas mesurée). Les fichiers nommés `*gsd*` sont 10 scripts ou références, plus
7 tests.

**Ce qui n'est qu'une délégation de prompt, donc remplaçable :**

- les tables de routage (`intent-routing.md`, `GSD-PIPELINE.md`, `docs-flow.md`,
  `mission-flow.md`, `mission-contracts.md`) ;
- les mentions dans les `AGENT.md`, `README.md` et `SKILL.md` (`vf-auto`, `vf-design`,
  `vf-sketch`, `vf-planning`…) ;
- les recommandations « next step ».

Tout cela se réécrit en prose, mais il faut alors **une cible** pour chaque geste nommé.

### 1.5 Format `.planning/` : qui l'écrit, qui le lit

- **Volume suivi par git sur origin/main : 1 051 fichiers**, dont :
  - 288 `PLAN.md` et 256 `SUMMARY.md` ;
  - 39 `CONTEXT.md` et 27 `DISCUSSION-LOG.md` ;
  - 26 `VERIFICATION.md`, 25 `PATTERNS.md`, 20 `VALIDATION.md` et 20 `RESEARCH.md`.

  Ce sont tous des artefacts au format des workflows GSD.
- **Qui écrit : le moteur GSD.** Ses workflows et ses agents passent par
  `gsd_run query <verbe>`. On compte **843 appels** répartis sur **181 verbes distincts**
  (`scratchpad/query-verbs.txt`). Les plus fréquents :
  - `config-get` (116), `commit` (93), `config-set` (49) ;
  - `agent-skills` (39), `resolve-model` (29), `resolve-dispatch-type` (25) ;
  - `roadmap.get-phase` (19), `init.phase-op` (18), `verification.status` (15) ;
  - `dispatch-isolation` (15), `roadmap.analyze` (14), `find-phase` (13) ;
  - `state.load` (9), `state.record-session` (7)…

  Le frontmatter de `STATE.md` (`gsd_state_version`, compteurs de phases et de plans) est calculé
  par `bin/lib/state.cjs` (ADR-063).
- **Ce que VibeFlow écrit lui-même (marginal) :**
  - les verrous (`driver-lock.sh`) ;
  - les archives (`.planning/archives/INDEX.tsv`, ADR-076) ;
  - `restore-requirements-ledger.sh` ;
  - le format propre à `planning-core` (`planning_version`) pour les **labs non-dev**, séparé de
    GSD par ADR-055.

  VibeFlow s'interdit d'écrire `STATE.md` par `gsd-tools state` (ADR-063).
- **Qui lit : VibeFlow.** **48 scripts hors tests** lisent `.planning`. Parmi eux :
  - les gates de dérive et d'intégrité : `check-divergence.sh`, `check-state-integrity.sh`,
    `check-workstream-pointer.sh`, `workstream-policy.sh`, `check-artifact-fidelity.sh`,
    `check-mission-invariants.sh`, `check-mission-exit.sh`, `check-requirements-survival.sh` ;
  - les hooks de contexte de session : `planning-context.sh`, `planning-task-context.sh` ;
  - `vibeflow-update.sh`, `recalc-planning.sh`, `check-method-budget.sh`,
    `check-instruction-budget.sh`, etc.

  Ces gates **encodent le format GSD** : ancre `^Phase:`, en-têtes `## Phase N`, noms de dossiers
  de phase, structure des workstreams.

**Conclusion du §1.** Les gates machine de VibeFlow lisent un format dont l'**écrivain** est
GSD. Retirer GSD laisse ce format sans écrivain, et c'est là le vrai coût de l'internalisation :
les 29 skills et les 26 agents viennent ensuite.

---

## 2. Taille de ce qu'il faudrait internaliser

### 2.1 gsd-core 1.19.0

Emplacement : `~/.npm/_npx/<hash>/node_modules/@opengsd/gsd-core`. Il est
installé dans `~/.claude/gsd-core/` (`.gsd-source` pointe vers `~/.claude/gsd-core/commands/gsd`).
`npm root -g` (`/opt/homebrew/lib/node_modules`) ne contient **pas** le paquet : il passe par le
cache `npx`.

- Licence : **MIT** (`LICENSE`, 21 lignes). `engines: node >=24`.
- Dépendances : `@anthropic-ai/claude-agent-sdk ^0.2.84` et `ws`. Poids sur disque : 22 Mo.

| bloc | fichiers | lignes |
|---|---|---|
| `skills/` (shims) | 72 | 4 119 md |
| `agents/` (35 complets + 29 `.compact`) | 64 | 23 258 md |
| `gsd-core/workflows/` | 186 (109 entrées de premier niveau) | 45 677 md |
| `gsd-core/references/` | 132 | 14 748 md |
| `gsd-core/templates/` | 40 | 7 360 md |
| `gsd-core/bin/` (CLI `gsd-tools` + 288 modules `lib/*.cjs`) | 303 | 189 426 cjs |
| `hooks/` | 85 | 21 540 js, 2 236 sh |
| `scripts/` (build et maintenance) | 166 | 48 579 cjs |
| **Total** | — | **120 162 md** ; **239 590 .cjs + 39 158 .js** |

**Part réellement utilisée** (approximation par homonymie skill → workflow) :

- les 29 skills du cœur : 1 962 lignes de shims et **24 365 lignes de workflows homonymes** ;
- les 27 agents cités : **13 808 lignes** ;
- les références partagées : 14 748 lignes, part utilisée **non mesurée** ;
- le moteur d'état (`gsd-tools`, verbes `query`) : il est appelé par toutes ces lignes. Combien des
  181 verbes se trouvent sur le chemin des 29 skills du cœur reste **non mesuré**.

Ordre de grandeur utilisé : **environ 40 000 à 55 000 lignes de prompt plus le sous-ensemble du
moteur cjs** dont dépendent ces workflows, sur 189 000 lignes de `bin/`.

### 2.2 superpowers 7.0.0

Emplacement : `~/.claude/plugins/cache/claude-plugins-official/superpowers/7.0.0`.

- Licence : **MIT**.
- Contenu : 15 skills, aucun agent, un hook `session-start`, 8 manifestes multi-runtime.
- Total du plugin : 33 884 lignes de md, dont `RELEASE-NOTES` et `docs/` ; 8 178 lignes de sh.
- Dossier `skills/` seul : 8 733 lignes de md (60 fichiers), 401 de sh, 336 de js et 158 de ts.

Les 6 skills cités par VibeFlow, en lignes de `SKILL.md` :

- brainstorming : 225, plus 8 fichiers dont un serveur Node, selon la mémoire ;
- writing-skills : 681 ;
- test-driven-development : 330 ;
- systematic-debugging : 283 ;
- verification-before-completion : 120 ;
- requesting-code-review : 95.

Total : **1 734 lignes**, hors fichiers annexes. Sur les seuls 3 skills « invoqués »
(brainstorming, TDD, verification) : **675 lignes**.

---

## 3. Comment AIDD est autonome

Source : clone dans `scratchpad/aidd-src`, lu sans rien exécuter.

- **Licence MIT.**
  - Une marketplace de **9 plugins** : `aidd-context`, `-dev`, `-orchestrator`, `-pm`, `-qa`,
    `-refine`, `-telemetry`, `-ui`, `-vcs`.
  - Au total **51 skills** et **2 agents** (`aidd-dev/agents/checker.md`, `executor.md`).
  - Les plugins tiennent en **16 403 lignes de md + 1 510 de cjs** (hooks : `update_memory.js`,
    `prompt-gate.cjs`, `session-start.cjs`…).
  - Aucune référence à gsd ni à superpowers (`grep -rl` vide).
- **Équivalents fonctionnels :**
  - plan → `aidd-dev:01-plan` ;
  - exécution → `02-implement` et l'agent `executor` ;
  - vérification → `03-assert`, `09-for-sure` et l'agent `checker` ;
  - revue → `05-review` et `04-audit` ;
  - orchestration → `aidd-orchestrator:01-sdlc`, `00-async-dev`, `02-backlog` ;
  - idéation → `aidd-refine:01-brainstorm` ;
  - vcs → `aidd-vcs:*`.
- **État = `aidd_docs/`** :
  - `memory/` ;
  - `tasks/<yyyy_mm>/<yyyy_mm_dd>_<slug>/` ;
  - `specs/`, `recipes/`, `runs/`, `async-runs/`.

  Ce sont des fichiers markdown que les skills écrivent eux-mêmes. Il n'y a **pas de moteur
  d'état** : ni compteurs dérivés, ni numérotation de phases centralisée, ni workstreams.
- **Mais AIDD a bien un gros composant de code** : la CLI `@ai-driven-dev/cli` 5.6.0, soit
  **157 653 lignes de TypeScript**. C'est un **installeur** (« install AI tool configs and plugins
  from the AIDD marketplace »), pas un moteur de planning.
- **Ce qui se compare :** la doctrine (skills en markdown autosuffisants, état sous forme de
  documents) et le fait d'être propriétaire de toute la chaîne.
- **Ce qui ne se compare pas.** VibeFlow possède **des gates machine qui lisent l'état** (48
  scripts). Ces gates supposent des invariants que seul un écrivain déterministe garantit :
  numérotation, frontmatter calculé, partition par workstream. AIDD n'a pas de tels gates, donc
  pas d'écrivain à remplacer. Pour être autonome « à la AIDD », VibeFlow devrait :
  - **soit** renoncer à ses gates sur l'état ;
  - **soit** posséder un écrivain d'état, c'est-à-dire réécrire la partie « état » de `gsd-tools`.

---

## 4. Options

Les coûts sont des **estimations** d'ordre de grandeur, pas des mesures. Une « phase » s'entend au
sens GSD du dépôt.

### (a) Statu quo

- **Coût :** 0 à l'instant t, mais un coût récurrent de dérive amont, déjà observé et coûteux :
  - le gate T28-F rougit tout seul quand `^1` publie ;
  - piège Node 24 : retour silencieux de 1.11 à 1.10 ;
  - régression de compteurs dans `STATE.md` (ADR-063) ;
  - `state record-session` est destructif ;
  - l'isolation par worktree est inerte (ADR-059) ;
  - migration legacy (ADR-058).
- **Risques :** un nouveau rug pull (précédent : le dépôt d'origine archivé le 2026-06-26), et le
  rythme amont d'environ 1 minor toutes les 2 semaines.
- **Ce qu'on garde :** la maintenance gratuite, les 19 runtimes et 18 hooks de garde.
- **Collisions :** aucune ; c'est la doctrine en vigueur (PROJECT.md *Out of Scope*, Iron Law 2
  révisée par ADR-069, doctrine GSD-first).

### (b) Internaliser superpowers seul

- **Coût :** environ **1 phase**.
  - Rapatrier 3 à 6 skills : 675 à 1 734 lignes de `SKILL.md` plus les annexes, dont le serveur
    HTTP de `brainstorming`.
  - Réécrire l'arête `brainstorming → writing-plans`. La mémoire chiffre 4 emplacements ; ce
    chiffre n'a pas été remesuré.
  - Retoucher environ 10 fichiers de routage ou de frontière et les deux scripts `ensure-*`.
  - Conserver la notice MIT.
- **Gain :** une dépendance dure de moins à l'installation, et un installeur multi-runtime plus
  simple.
- **Perte :** les mises à jour amont des skills de discipline.
- **Risque et collision :** ADR-057 dit que superpowers « appartient à l'utilisateur » et ne peut
  pas être dé-publié. S'il reste installé sur le poste, on **double** la concurrence de routage
  (`vf-brainstorming` contre `superpowers:brainstorming`), soit l'inverse de ce que visait
  ADR-057. ADR-058 §6 et la mémoire font de ce rapatriement un **plan de secours**, avec un
  déclencheur (« si rug pull ») qui n'est pas atteint.
- **Gain sur la question de Samuel :** faible. Superpowers n'est pas le couplage structurant
  (10 fichiers sur 557).

### (c) Vendoring : forks figés de gsd-core et de superpowers dans le plugin

- **Coût initial :** environ **2 à 3 phases**.
  - Embarquer 22 Mo et environ 400 000 lignes : 120k de md et 279k de js/cjs.
  - Reprendre l'installeur, qui pose `~/.claude/gsd-core`, 18 hooks dans `settings.json` et la
    conversion vers 19 runtimes.
  - Rebrancher les cascades de résolution et la CI.
- **Coût récurrent :** les correctifs de sécurité et les adaptations aux évolutions de Claude
  Code, à notre charge. Le dossier `~/.claude/gsd-local-patches/` montre que nous patchons déjà
  localement.
- **Licences :** MIT pour les deux, compatibles. Il faut garder les notices, alors que le plugin
  est `UNLICENSED`.
- **Gain :** le moteur est figé, il n'y a plus de dérive (T28-F, Node) et plus de risque de rug
  pull.
- **Perte :** les releases amont gratuites ; Node ≥ 24 **reste** obligatoire.
- **Collisions :**
  - PROJECT.md *Out of Scope* : « Fork/réécriture des skills GSD — on délègue, on n'absorbe pas » ;
  - Iron Law 2 révisée : « Router, jamais forker » (ADR-069) ;
  - ADR-030 : déléguer, ne jamais réimplémenter ;
  - doctrine GSD-first.

  Il faut un arbitrage explicite de Samuel pour amender ces règles.

### (d) Internalisation sélective : réécrire les gestes utilisés et garder le format `.planning/`

- **Coût :** environ **6 à 12 phases** (estimation peu sûre).
  - Réécrire les 29 skills du cœur (environ 24k lignes de workflows) et les 26 agents (environ
    14k lignes).
  - Écrire un **écrivain d'état** compatible avec le format actuel : calcul du frontmatter de
    STATE, `roadmap analyze`, `find-phase`, numérotation, `commit`, workstreams, config. On ne
    sait pas encore combien des 181 verbes sont réellement nécessaires.
  - Requalifier les 48 gates lecteurs.
- **Gain :**
  - c'est la seule option qui supprime GSD **et** garde l'historique (1 051 fichiers
    `.planning`) ainsi que les gates ;
  - on peut réécrire en bash ou en python, comme le reste du dépôt, ce qui permettrait de sortir
    de Node 24 si l'écrivain ne dépend pas du SDK.
- **Pertes et risques :**
  - réimplémenter un format qu'on ne contrôle pas : le format GSD continue d'évoluer, et les
    labs déjà sous GSD divergeraient ;
  - perte des hooks de garde amont et des 19 runtimes ;
  - risque de régressions silencieuses dans les gates (mémoire « une preuve doit pouvoir rendre
    rouge »).
- **Collisions :** les mêmes qu'en (c), et plus fortement : c'est exactement le « fork d'une
  capacité » qu'ADR-069 maintient interdit.

### (e) Remplacement complet par un moteur VibeFlow propre

- **Coût :** **plus de 12 phases**, c'est-à-dire un jalon entier.
  - Moteur, skills, agents, installeur, multi-runtime.
  - Migration ou gel des 1 051 fichiers `.planning`, et migration des labs installés.
- **Gain :**
  - une autonomie totale, au sens d'AIDD ;
  - un format conçu pour nos gates ;
  - plus aucune frontière ADR-055 ou ADR-057 avec GSD.
- **Perte :** tout l'acquis amont, et une charge permanente de mainteneur de moteur.
- **Risque :** le plus haut. Selon la mémoire `gsd-succession-landscape-2026-07`, « l'espace
  vacant n'est PAS un GSD maintenu (il existe) mais la couche au-dessus ».
- **Collisions :** toutes celles de (c) et (d), plus la remise en cause de la doctrine de
  positionnement produit.

### Synthèse

| option | coût (estimé) | risque | supprime GSD ? | collisions ADR |
|---|---|---|---|---|
| (a) statu quo | 0 + dérive récurrente | moyen (amont) | non | aucune |
| (b) superpowers seul | ~1 phase | faible, mais concurrence de routage doublée | non | ADR-057, ADR-058 §6 (plan de secours) |
| (c) vendoring | 2-3 phases + maintenance | moyen (sécurité, Claude Code) | dépendance réseau oui, code non | Out of Scope, Iron Law 2, ADR-030 |
| (d) sélectif | 6-12 phases | élevé (format, régressions de gates) | oui | idem, plus fort |
| (e) moteur propre | >12 phases | très élevé | oui | idem + positionnement |

---

## 5. Recommandation

**Ne pas internaliser maintenant : garder (a), et le durcir.** Préparer (c) comme plan de
secours chiffré, au même titre que (b).

Raisons :

1. Le couplage structurant est le **format `.planning/` écrit par le moteur et lu par 48 gates**.
   Aucune option bon marché ne le supprime. (b) ne touche pas GSD, et (d) ou (e) demandent de
   réécrire l'écrivain d'état.
2. Les deux paquets sont MIT. Le jour d'un rug pull, (c) devient faisable en 2 à 3 phases à
   partir de la dernière version publiée. Le risque principal d'(a) est donc **couvert par une
   option de repli**, à condition de garder une copie locale de la dernière version saine.
3. Les douleurs mesurées de la dépendance (T28-F, Node 24, ADR-063) viennent de la **plage
   flottante `^1`** et des changements de forme du moteur, pas de la dépendance en soi.

   **Suggestion, non arbitrée :** épingler une version exacte dans `ensure-deps.sh` et dans la
   CI, puis monter de version volontairement via `/vf-update` (ADR-058). On garderait ainsi la
   maintenance amont sans subir la dérive.

   Cette suggestion touche ADR-058 (la plage `^1` y est « une décision de VibeFlow ») : à
   soumettre à Samuel.
4. Si Samuel veut quand même l'autonomie « à la AIDD », la seule voie cohérente avec les gates
   est (d), cadrée comme un jalon. Il faut alors **amender d'abord** PROJECT.md *Out of Scope*,
   l'Iron Law 2 (ADR-069) et ADR-030. C'est un arbitrage humain, à ne pas inférer.

## 6. À mesurer avant de trancher (non mesuré ici)

1. **La fréquence réelle d'invocation** des skills et agents gsd-* et superpowers:* dans les
   transcripts de session (`~/.claude/projects/*/*.jsonl`). Ce rapport compte des **mentions**,
   pas des appels.
2. **Les verbes `gsd-tools query` réellement sur le chemin** des 29 skills du cœur, parmi les 181,
   avec les lignes de `bin/lib` qu'ils entraînent. C'est ce qui conditionne le coût de (d).
3. **Le coût historique de la dérive amont** : nombre de PR et de hotfixes, et heures passées
   depuis la migration vers gsd-core (juillet 2026). Les mémoires citent T28-F, Node 24, ADR-063,
   le hotfix des flux JSON et les canaris de forme, mais aucun total n'est chiffré.
4. **Le rythme de changements cassants** de gsd-core entre 1.8 et 1.19 (changelog amont).
5. **L'usage de GSD en direct** par les autres utilisateurs (Willy, testeurs) en dehors de
   VibeFlow.
6. **La part de `gsd-core/references/`** (14 748 lignes) chargée par les workflows du cœur.
7. **La dépendance des 48 gates lecteurs** : lesquels supposent un invariant que seul l'écrivain
   GSD garantit, et lesquels se contentent d'un format markdown stable.

## Annexes (scratchpad)

- `gsd-names.txt` : toutes les occurrences `gsd-*`, avec leur nombre.
- `usage-table.txt` : nom → nombre de fichiers appelants → fichiers (tests, CHANGELOG et index
  exclus).
- `skills-usage.txt`, `agents-usage.txt` : la même table, restreinte aux skills puis aux agents.
- `query-verbs.txt` : les 181 verbes `gsd_run query`, avec leur nombre d'appels.
- `planning-files.txt` : les 1 051 fichiers `.planning` suivis par git sur origin/main.
- `ADR.md` : copie d'`origin/main:docs/ADR.md`. Sections lues : ADR-055, 057, 058, 063, 069
  (Iron Law 2) et l'amendement du 2026-10-20.
