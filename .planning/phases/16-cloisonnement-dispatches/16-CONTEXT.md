# Phase 16: Cloisonnement des dispatches — Context

**Gathered:** 2026-07-27 (rédigé a posteriori — la phase a été exécutée en mission d'équipe le
2026-07-27 sans `16-CONTEXT.md` préalable ; ce document reconstitue le cadrage de référence à
partir des 5 commits produits, pour la relecture future)
**Status:** Phase exécutée et vérifiée (voir `<code_context>` pour le gate final)

<domain>
## Phase Boundary

### Le problème

Le cloisonnement des dispatches (Pattern 12, ADR-044) était **documenté et testé par module**
— chaque agent déclare son `tools:`, chaque suite de module vérifie sa propre conformité — mais
**pas garanti par le gate partagé** `plugin/conductor/scripts/check-agents.sh` : celui-ci lisait
la présence/absence des champs du frontmatter (model, memory, description, skills) mais ne
lisait **jamais le contenu** du champ `tools:`. Une allowlist `Agent(...)` opaque passait
`--strict` en vert quelle que soit sa syntaxe : nom d'agent inventé, parenthèse non fermée,
allowlist vide, entrée vide, tokens hors charset, outil mal orthographié (« Reed »). Et le gate
ne couvrait, côté cloisonnement métier, que le chemin **direct** manager→manager (verrouillé
depuis la Phase 15) — pas le chemin **indirect** worker→manager, resté ouvert sur trois workers
de l'équipe dev (`vf-coder`, `vf-reviewer`, `vf-auditer`), qui déclaraient `Agent` nu sans
allowlist du tout.

Livre :
1. Un lint réel du contenu des allowlists `Agent(...)`/`Task(...)` dans `check-agents.sh` —
   syntaxe (bloquant) + résolution de noms (graduée, voir `<decisions>`).
2. Des allowlists `Agent(...)` recensées et posées sur les trois workers internes de l'équipe
   dev, fermant le chemin indirect par déclaration et par lint.
3. Un run CI « monde fermé » (`--resolve-agents=strict`) sur l'union des registres d'agents du
   repo — le seul endroit où l'univers complet est connu.
4. La correction de deux affirmations doctrinales devenues fausses après le lint (voir
   `<code_context>`).

**Ne produit PAS** :
- Aucune modification du kernel (`dag.sh`, `driver-lock.sh`) — le verrou de driver reste le seul
  garant machine réel de l'invariant « un seul manager actif », les allowlists n'en sont pas un
  substitut runtime (voir §4 ci-dessous).
- Aucune allowlist posée sur un manager (`vf-dev-manager`, `vf-design-manager`) — déjà traité en
  Phase 15, hors périmètre ici.
- Aucun manifeste externe de noms d'agents connus (option écartée, voir `<decisions>`).

</domain>

<decisions>
## Implementation Decisions

### Le piège qui avait fait renoncer la Phase 15 à écrire ce lint (cœur du document)

Un lint naïf exigeant que chaque nom listé dans `Agent(...)` résolve vers un fichier
`<agents-dir>/<nom>.md` rendrait **rouges des allowlists correctes**, pour trois familles de noms
légitimes qui ne résolvent structurellement vers aucun fichier :

- **(a) Types d'agents natifs sans `.md`** : `general-purpose`, `Explore`, `Plan`,
  `statusline-setup`, `claude-code-guide`, `fork` — livrés par le runtime Claude Code, jamais
  posés comme fichier dans un `agents-dir`.
- **(b) Agents tiers `gsd-*`** du paquet npm `@opengsd/gsd-core` — absents de tout lab qui n'a
  pas installé GSD, alors que `vf-coder` en dispatche 20 (cadrage, plan, exécution, revue).
- **(c) Agents d'un autre module VibeFlow non installé** — l'allowlist de `vf-dev-manager` cite
  `vf-crafter`/`vf-design-judge`, qui vivent dans `design-orchestrator`, pas dans
  `dev-orchestrator`.

**D-01 — Résolution graduée, auto-contenue dans le script.** La sévérité dépend de ce qui est
vérifiable **indépendamment du périmètre installé** :
- **Syntaxe → erreur dure** (parenthèse équilibrée, allowlist non vide, entrée non vide, charset,
  espace avant parenthèse) : ne dépend d'aucun scope, toujours vérifiable.
- **Noms d'outils → warning par défaut, erreur en `--strict`** : le set d'outils Claude Code est
  un set fermé documenté par la doc officielle — vérifiable partout.
- **Noms d'agents non résolus → warning, y compris sous `--strict`** ; erreur **seulement** sous
  le mode opt-in `--resolve-agents=strict`, réservé à la CI, seul endroit où l'univers des
  agents est réellement connu (union de tous les `plugin/*/agents`).

**Justification (pourquoi pas plus strict par défaut) :** la doc officielle **ne fige pas** la
liste des types natifs — marqueurs `min-version`, `output-style-setup` disparu depuis,
désactivation par variable d'environnement, override possible par un agent utilisateur portant
le même nom. Toute règle qui transformerait « nom non résolu » en erreur bloquante par défaut est
donc un pari sur une liste qui bougera dans le temps — et ce dépôt a déjà payé ce pari exactement :
c'est la dette « 66 faux positifs » de `CONCERNS.md`/`BACKLOG.md`, désormais fermée (voir
`<code_context>`).

**D-02 — Option écartée : manifeste externe de noms connus.** Deux contraintes l'ont exclue :
`copy_module_scripts()` (`plugin/_internal/vibeflow-update.sh:337-352`) ne copie que les
fichiers `*.sh|*.mjs|*.js` — un fichier de données (`known-agents.txt` ou équivalent) ne serait
**jamais posé** chez l'utilisateur. C'est le mécanisme exact qui a fait manquer
`known-versions.txt` (cf. mémoire du remédiation 2026-07-26) : ne pas répéter l'erreur. La
résolution devait donc rester interne au script (registres passés en argument à l'exécution,
`--agent-registry-dir`), jamais un fichier de données livré par le module.

### Le protocole de recensement (ce qui rend les allowlists dignes de confiance)

Une allowlist incomplète casse des dispatches en production silencieusement — deux recensements
successifs en Phase 15 avaient déjà produit 4 omissions sur ce type d'exercice. Pour ne pas
répéter l'erreur, le recensement des trois workers a suivi **deux dérivations indépendantes
menées en parallèle**, réconciliées ensuite :
- **Bottom-up** : lecture des prompts des trois agents + leurs `references/` + les agents nommés
  par chaque skill qu'ils invoquent (`gsd-discuss-phase`, `gsd-plan-phase`, `gsd-execute-phase`,
  `gsd-code-review`, `gsd-secure-phase`, etc.).
- **Top-down** : partir de la question « quel geste, quelle machinerie, qu'est-ce qui casse si
  l'allowlist est incomplète ? » puis balayer en sens inverse **tous les agents du système** pour
  vérifier qui pourrait légitimement être dispatché par chacun des trois workers — cette
  dérivation était **explicitement interdite** de lire les inventaires déjà produits par la
  dérivation bottom-up, pour rester une preuve indépendante et non une simple relecture.
- **Réconciliation** des écarts entre les deux listes par le manager (`vf-dev-manager`), qui
  arbitre l'union.

**D-03 — Fait structurant qui justifie ce protocole.** Aucune skill n'a de `context:` propre,
donc **aucune n'est forkée** : les `Task(...)` internes à une skill sont exécutés par l'agent qui
l'invoque, **sous SA PROPRE allowlist**. C'est précisément la couche qu'un recensement naïf
(« lister les agents que le prompt du worker mentionne ») rate systématiquement, parce que la
majorité des dispatches réels d'un worker comme `vf-coder` ne sont pas écrits en toutes lettres
dans son propre prompt — ils sont hérités par transitivité des skills GSD qu'il invoque.

**Fait discriminant vérifié empiriquement** (pas déduit) : **`vf-coder` possède le tool `Skill`**
dans son `tools:` — donc l'expansion transitive décrite ci-dessus s'applique bien à lui, d'où ses
22 noms. **`vf-reviewer` et `vf-auditer` n'ont pas `Skill`** dans leur `tools:` — ils ne
délèguent qu'à un unique agent outillé chacun (`gsd-code-reviewer`, `gsd-security-auditor`),
d'où leur allowlist à 1 seul nom.

### La portée réelle de l'allowlist, sans surestimation

**D-04 —** Selon la doc officielle sub-agents
(`https://code.claude.com/docs/en/sub-agents`, citation vérifiée le 2026-07-27) : *« The
Agent(agent_type) allowlist syntax applies only to an agent running as the main thread with
`claude --agent`. In a subagent definition, listing Agent in tools lets that subagent spawn
subagents of its own [...], but any type list inside the parentheses is ignored. »* Concrètement,
pour un agent posé sous `.claude/agents/` et donc **toujours dispatché en sous-agent** (jamais
incarné en thread principal), le runtime **ignore** la liste de noms entre parenthèses — seule la
présence du mot `Agent`/`Task` dans `tools:` compte pour le runtime.

L'allowlist `Agent(...)` est donc un **contrat documenté, désormais enforcé par le lint** — pas
un bac à sable runtime. Elle ne redevient une vraie restriction d'exécution que pour un agent
incarné en thread principal (`claude --agent`). Le **verrou de driver**
(`plugin/conductor/scripts/driver-lock.sh`) reste, à ce titre, le seul garant machine réel de
l'invariant « un seul manager actif » — pas les allowlists, qui ne sont qu'une deuxième ligne de
contrat/lint, jamais un cloisonnement runtime indépendant.

### Claude's Discretion (déjà tranché en exécution, noté pour mémoire)

- Formulation exacte des messages d'erreur/warning du lint (le code fait foi).
- Reformulation des descriptions des trois workers (« dispatché UNIQUEMENT par vf-dev-manager »
  → « par un manager du team-kernel (vf-dev-manager, vf-design-manager) » pour `vf-coder`) et de
  l'échappatoire texte qui autorisait à dispatcher « l'agent équivalent via Task » sans
  contrainte — recadrée pour ne dispatcher que parmi les agents listés dans `tools:`, sinon
  remonter `blocked`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before touching ce périmètre.**

- `plugin/conductor/scripts/check-agents.sh` (en-tête, lignes ~1-80) — doctrine complète du lint,
  citation verbatim de la doc sub-agents, sémantique des flags.
- `plugin/conductor/scripts/tests/test-check-agents.sh` — 54 axes, T19/T26/T29/T30/T30b et
  T37-T50 couvrent spécifiquement les classes de la Phase 16.
- `plugin/dev-orchestrator/agents/vf-coder.md`, `vf-reviewer.md`, `vf-auditer.md` — allowlists
  posées, ligne `tools:`.
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` T19-T19f.
- `plugin/dev-orchestrator/references/mission-cross-team.md` — passages corrigés sur l'attribution
  de la fermeture du chemin indirect.
- `plugin/conductor/README.md`, `plugin/conductor/references/team-kernel.md` — doctrine « deux
  lignes de défense » corrigée (D-04).
- `.github/workflows/ci.yml` — run monde fermé (`--resolve-agents=strict`,
  `--agent-registry-dir` répété sur l'union des `plugin/*/agents`).
- `https://code.claude.com/docs/en/sub-agents` — source de vérité sur la portée runtime des
  allowlists (citation D-04).
- `.planning/codebase/CONCERNS.md` — dette « `check-agents.sh --strict` sans périmètre tiers »
  et dette « Accès `Agent` non scopé sur trois workers » : toutes deux retirées par cette phase.
- `.planning/BACKLOG.md` — item correspondant clos.

</canonical_refs>

<code_context>
## Existing Code Insights

### Ce qui a été trouvé en cours de route par les juges (utile au prochain qui touchera ce code)

Deux juges indépendants (revue de code + mutation) ont trouvé 4 défauts dans le lint neuf,
corrigés dans le commit `d3a8f53` :
1. **Faux-bloquant — champ entièrement quoté** : `tools: "Read, Agent(x)"` (YAML parfaitement
   valide) produisait deux faux BLOQUANTS (charset + parenthèse non fermée), parce que
   `extract_raw_field`/`tokenize_field` ne dé-quotaient jamais le raw avant le split à profondeur
   de parenthèses (alors que `parse_frontmatter` le faisait déjà pour les scalaires). Corrigé :
   dé-quote une seule paire englobante avant tout traitement.
2. **Faux-bloquant — ligne vide dans une liste bloc YAML** : `tools:\n  - Read\n\n  - Agent(x)`
   faisait perdre **silencieusement** toute puce suivante — la collecte de bullets s'arrêtait
   (`break`) sur la première ligne non-puce, y compris une ligne vide, contrairement à
   `parse_frontmatter` qui tolère les lignes vides. Corrigé : la boucle ne s'arrête plus que sur
   une nouvelle clé.
3. Détection de parenthèse **en trop** (`Agent(a)))`) non couverte par `analyze_token` — seul
   `split_depth` la portait, et le seul test existant (T26, parenthèse manquante) faisait doublon
   sans discriminer cette classe. Nouvel axe dédié (T37).
4. Trois classes documentées BLOQUANT dans l'en-tête mais jamais testées (virgule orpheline,
   entrée vide interne, espace avant la parenthèse) : le code les gérait déjà, seule la
   couverture manquait (T38-T40). Relecture complète a comblé d'autres classes non testées
   (T41-T50).

Deux axes de test **tautologiques** ont aussi été corrigés (`be778a8`) : `check_worker_allowlist`
(T19/T19e) cherchait le nom sur **toute la ligne `tools:`** (`grep -qF`) au lieu de l'intérieur
de `Agent(...)` — un nom déplacé en `Bash(gsd-verifier)` ailleurs sur la même ligne restait
« trouvé », vidant la couverture du point le plus sensible du cloisonnement. Deux helpers testés
par mutation réelle ont remplacé le grep naïf : `extract_agent_allowlist` (isole le contenu entre
`Agent(` et sa `)` correspondante par comptage de profondeur) et `allowlist_has_name`
(appartenance par égalité de token exacte après split sur virgule, jamais par sous-chaîne —
immunise contre un homonyme partiel, prouvé par T19f : `gsd-ui-checker` vs `gsd-ui-researcher`,
`gsd-code-reviewer` vs `gsd-code-fixer`, `gsd-planner` vs `gsd-plan`/`gsd-plan-checker`).

Toutes les corrections ont été prouvées discriminantes par mutation réelle (rouge sans le check,
vert avec, restauration après coup) avant d'être ajoutées aux suites — jamais acceptées sur
lecture de code seule.

### Le recensement consolidé des trois allowlists (nom par nom, état sur disque au 2026-07-27)

**`vf-coder`** (`tools:` porte `Skill` → expansion transitive, 22 noms) :
`vf-reviewer`, `general-purpose`, `gsd-assumptions-analyzer`, `gsd-phase-researcher`,
`gsd-pattern-mapper`, `gsd-planner`, `gsd-plan-checker`, `gsd-executor`, `gsd-codebase-mapper`,
`gsd-verifier`, `gsd-code-reviewer`, `gsd-code-fixer`, `gsd-debugger`, `gsd-integration-checker`,
`gsd-nyquist-auditor`, `gsd-ui-researcher`, `gsd-ui-checker`, `gsd-ui-auditor`,
`gsd-framework-selector`, `gsd-ai-researcher`, `gsd-domain-researcher`, `gsd-eval-planner`.

**`vf-reviewer`** (pas de `Skill` dans `tools:`, un seul dispatch direct) : `gsd-code-reviewer`.

**`vf-auditer`** (pas de `Skill` dans `tools:`, un seul dispatch direct) : `gsd-security-auditor`.

Aucun manager (`vf-dev-manager`, `vf-design-manager`) dans aucune des trois allowlists.

### Gate final mesuré (2026-07-27, reproduit lors de la clôture documentaire)

- 40/40 suites du repo vertes ; `test-check-agents.sh` 54 OK/0 KO ; `test-dev-orchestrator.sh`
  51 OK/0 KO/0 SKIP.
- 6/6 modules porteurs d'agents passent `check-agents.sh --strict` exit 0 ; monde fermé
  (`--resolve-agents=strict` sur l'union des registres) exit 0 ; `check-version-sync.sh` exit 0.
- Vérification indépendante (hors mission, à date de rédaction de ce document) :
  `check-agents.sh --strict --agents-dir="$HOME/.claude/agents"` (scope utilisateur réel,
  67 agents dont 34 `gsd-*`) → **exit 0**, 34 agents tiers exclus par `--third-party-prefix`,
  0 erreur, 26 warnings résiduels sur des agents réels non-`gsd-*` (hors périmètre de cette
  dette — dette distincte, non traitée ici). Sans le flag (`--no-third-party-prefix`), les
  erreurs `gsd-*` réapparaissent en masse (169 lignes ✗/⚠) — confirme empiriquement que c'est le
  flag, et non une coïncidence de version, qui ferme le faux positif historique des 66
  non-conformités.

</code_context>

<specifics>
## Specific Ideas

- Le point de vigilance n°1 de cette phase (hérité du même avertissement en Phase 15) était le
  recensement : une allowlist posée sans double dérivation indépendante casse des dispatches en
  production silencieusement. Le fait que `vf-reviewer`/`vf-auditer` n'aient qu'un seul nom
  chacun n'est pas une simplification arbitraire — c'est la conséquence directe et vérifiée de
  l'absence du tool `Skill` dans leur `tools:`.

</specifics>

<deferred>
## Deferred Ideas

- Les 26 warnings résiduels sur `~/.claude/agents` (agents réels non-`gsd-*` : `conductor.md`,
  `design-orchestrator.md`, `dev-orchestrator.md`, `skill-creator.md`, `validator.md`, et des
  versions installées non à jour de `vf-coder`/`vf-auditer`/`vf-reviewer`/`vf-dev-manager`/
  `vf-design-manager` portant encore un `Agent` nu) ne sont **pas** une nouvelle dette ouverte par
  cette phase — ce sont des classes déjà connues (tools absent, aucun skill câblé, name ≠ nom de
  fichier) sur des agents dont la copie installée sur cette machine n'a pas encore été
  resynchronisée avec l'état du repo. Non traité ici : hors périmètre de la Phase 16, qui portait
  sur le lint et les trois workers, pas sur la resynchronisation d'une machine.

</deferred>

---

*Phase: 16-cloisonnement-dispatches*
*Context reconstitué : 2026-07-27*
