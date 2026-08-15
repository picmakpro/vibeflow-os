# Phase 15: Collaboration inter-équipes dev ↔ design - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Faire collaborer les deux équipes de mission (dev-orchestrator, design-orchestrator) **par étages
croisés sous UN SEUL manager** — option A de l'étude 15-ETUDE (validée par 7 tests empiriques) :
un seul verrou de driver, un seul DAG, un seul rapport de mission.

Livre :
1. `vf-dev-manager` : étage design en mission dev (nœuds `craft:<écran>` via `vf-crafter` avant
   l'exécution, `critique:<écran>` via `vf-design-judge` en parallèle de la revue code).
2. `vf-design-manager` : étage implémentation en mission design (dispatch de `vf-coder` pour
   incarner les specs du crafter, opt-in par brief).
3. Fix `vf-auto` : aiguillage mission longue à dominante design → `Task(vf-design-manager)`.
4. Allowlists `Agent(...)` sur les deux managers (interdiction d'imbrication machine-enforced).
5. Tests croisés dans les suites des deux modules + release-meta des modules touchés.

**Ne produit PAS** :
- Aucune imbrication manager→manager (Pattern A intact — prouvé bloquant par T1, c'est voulu).
- Aucune modification des scripts kernel (`dag.sh`, `driver-lock.sh`) — T3/T4 prouvent qu'ils
  supportent déjà les DAG hétérogènes et le reopen cross-métier.
- Aucune intégration « Claude Design » / génération de design system connecté (idée différée).
- Le bump `VERSION` racine + tag = étape de release sous validation humaine (convention Phase 13) —
  planifiable en dernier plan mais jamais exécutée sans confirmation explicite.

</domain>

<decisions>
## Implementation Decisions

### Détection « étape UI » (quand l'étage design s'insère en mission dev)
- **D-01:** **Jugement du manager au plan de bataille** : `vf-dev-manager` décide en planifiant
  (objectif de l'étape dans la ROADMAP, présence d'un UI-SPEC/`DESIGN.md`, nature des livrables) et
  matérialise sa décision dans le DAG (nœuds craft/critique posés ou non). Pas d'heuristique
  mécanique sur les fichiers, pas de marqueur humain obligatoire.
- **D-02:** **Le brief prime** : le contrat de mission (`mission-contracts.md` §Brief) gagne un champ
  optionnel `design: auto|force|off` (défaut `auto` = jugement du manager). — **Reversibility:**
  costly — le champ entre dans le contrat de brief publié, consommé par vibeflow-dev, vf-auto et les
  deux managers ; le retirer toucherait tous ces consommateurs.
- **D-03:** **Granularité : nouvel écran + refonte seulement.** Un fix UI mineur (typo, spacing
  ponctuel) reste dans le cycle `vf-coder` classique — proportionnalité du kernel (l'équipe pour les
  missions, pas le quotidien).

### Absence de DA (`DESIGN.md` manquant) en mission dev
- **D-04:** **Étage sauté + signalé** : l'étape suit le cycle `vf-coder` classique ; le rapport de
  mission consigne « étage design sauté, pas de DA » et propose **DA-INIT** (geste existant du module
  design) comme next step. Cohérent avec la doctrine design (« pas de DESIGN.md → pas de refonte
  structurante, jamais de DA inventée en mission ») et ADR-031. Jamais de craft sans DA, jamais de
  HALT bloquant pour ça.

### Handoff design → dev (implémentation des specs du crafter)
- **D-05:** **Opt-in par brief** : le brief de mission design porte un champ
  `livrable: specs|specs+implementation`, défaut `specs` (comportement actuel du module, zéro
  surprise). L'agent `vibeflow-design` propose le mode complet quand le projet a du code. —
  **Reversibility:** costly — même raison que D-02 (contrat de brief publié).
- **D-06:** **Double juge sur le rendu implémenté** : en mode `specs+implementation`, après
  l'implémentation par `vf-coder` → `vf-design-judge` re-score le rendu contre la DA **ET**
  `vf-reviewer` relit le diff, **en parallèle** (juges read-only, même frontière DAG). « Vert »
  complet = critique ≥ seuil ET revue PASS. Symétrique de l'étage vérification dev (test ∥ audit).

### Cloisonnement machine-enforced
- **D-07:** **Allowlists `Agent(...)` sur les DEUX managers** : un manager ne PEUT PAS dispatcher
  l'autre manager — l'interdit du Pattern A devient structurel (Pattern 12, linté par
  `check-agents.sh`). Attention au périmètre : l'allowlist de `vf-dev-manager` doit couvrir TOUS ses
  dispatches existants (vf-coder, vf-reviewer, vf-auditer, vf-test-orchestrator,
  gsd-advisor-researcher, chercheurs doc ADR-045 : general-purpose / gsd-phase-researcher, et les
  agents gsd-* qu'il dispatche via la chaîne) + les nouveaux (vf-crafter, vf-design-judge) — une
  allowlist incomplète casserait des dispatches déjà en production. Celle de `vf-design-manager` :
  vf-crafter, vf-design-judge + vf-coder, vf-reviewer (+ chercheurs si sa doctrine en dispatche). —
  **Reversibility:** reversible — retirer une allowlist rouvre l'outil sans casser d'appel.

### Seuil design en mission dev
- **D-08:** **Bloquant, même régime que l'équipe design** : critique < seuil (70/100,
  `VF_DESIGN_SEUIL`) → `dag.sh reopen` du craft (3 tours max), puis HALT/escalade si toujours rouge.
  Un seul standard de qualité design, quel que soit le manager qui pilote.

### Budget anti-thrash en mode specs+implementation
- **D-09:** **Budgets séparés 3 + 3 par écran** : 3 tours max craft→critique (la spec), puis 3 tours
  max implémentation→(re-critique ∥ revue). Deux boucles de nature différente, deux compteurs —
  chaque étage garde la sémantique kernel existante.

### Digest cross-métier
- **D-10:** **Digest enrichi croisé** (toujours ≤ 30 lignes, le disque fait foi) : mandat
  dev→crafter/judge embarque la DA en 3-5 lignes (tokens clés, personnalité — même format que le
  digest design existant) ; mandat design→coder/reviewer embarque les conventions code cibles
  (CLAUDE.md projet, commits, périmètre fichiers). Pas de nouvelle section formelle dans
  `mission-contracts.md` — enrichissement du format existant.

### Aiguillage vf-auto
- **D-11:** **Design pur → design ; sinon dev** : mission entièrement design (refonte multi-écrans,
  harmonisation, zéro feature) → `Task(vf-design-manager)` ; toute mission mixte ou dev →
  `Task(vf-dev-manager)`, qui insère les étages design où il faut (D-01..03). Pas de comptage de
  dominante — règle simple, un seul pilote par mission. Honore enfin la description publiée de
  `vf-design-manager`.

### Claude's Discretion
- Formulations exactes des doctrines dans les agents/références (sous plafonds ADR-029 : agents
  ≤ 250 lignes — `vf-dev-manager.md` est à 172, `vf-design-manager.md` à 137).
- Où loger la doctrine croisée : enrichir `mission-flow.md`/`team-kernel.md` vs nouveau fichier de
  référence — au choix du planner, pattern Phase 13 D-01 (référence on-demand + renvoi).
- Reformulation des descriptions des workers (« dispatché UNIQUEMENT par vf-design-manager » devient
  « par un manager du team-kernel (vf-design-manager, vf-dev-manager) » — même geste pour vf-coder
  et vf-reviewer côté design). `vf-internal: true` reste sur tous les workers.
- Numérotation des nouveaux axes de test (suites des deux modules, gabarit T15/T16 de la Phase 13),
  et intégration du scénario `test-collab-orchestrateurs.sh` (lock croisé, DAG mixte, reopen
  cross-métier) dans les suites.
- Bumps par module (convention CLAUDE.md : capacité → minor ; table team-kernel.md du conductor à
  mettre à jour → patch conductor probable). La release racine reste sous validation humaine.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Étude et preuve de faisabilité (source primaire de cette phase)
- `.planning/phases/VFDO-15-collaboration-inter-quipes-dev-design/15-ETUDE-collaboration-dev-design.md`
  — état des lieux, 3 trous, options comparées, périmètre. **À lire en premier.**
- `.planning/phases/VFDO-15-collaboration-inter-quipes-dev-design/test-collab-orchestrateurs.sh`
  — scénario empirique rejouable (7/7 PASS), base des nouveaux axes de test.

### Contrat d'équipe (le kernel que la phase étend sans le modifier)
- `plugin/conductor/references/team-kernel.md` — contrat universel manager→workers→juges ; la table
  « Implémentations » devra refléter les étages croisés.
- `plugin/dev-orchestrator/references/mission-flow.md` — Patterns A/B/C, pipelining N/N+1, `$S`.
- `plugin/dev-orchestrator/references/mission-contracts.md` — §Brief (champs `design:`, `livrable:`
  à ajouter), §Digest (enrichissement croisé D-10), signaux de mission.

### Agents à modifier
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` (172/250 lignes) — étage design + allowlist.
- `plugin/design-orchestrator/agents/vf-design-manager.md` (137/250 lignes) — étage implémentation + allowlist.
- `plugin/design-orchestrator/agents/vf-crafter.md`, `vf-design-judge.md` — descriptions (dispatch élargi).
- `plugin/dev-orchestrator/agents/vf-coder.md`, `vf-reviewer.md` — descriptions (dispatch élargi).
- `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` — aiguillage D-11.
- `plugin/dev-orchestrator/AGENT.md` (vibeflow-dev) et `plugin/design-orchestrator/AGENT.md`
  (vibeflow-design) — signaux mission à aligner (brief `design:`/`livrable:`).

### Gates machine et tests
- `plugin/conductor/scripts/check-agents.sh` — lint des allowlists `Agent(...)` (Pattern 12, ADR-044).
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (T1..T17 pris) et
  `plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` (T1..T7 pris) — suites à étendre.
- `plugin/conductor/scripts/tests/test-driver-lock.sh`, `test-dag.sh` — baseline kernel (ne pas toucher).

### Doctrine transverse
- `CLAUDE.md` (racine repo) — densité ADR-029, ADR-031, ADR-044, discipline de release (version = tag).
- `.planning/ROADMAP.md` §Phase 15 — Goal + 5 Success Criteria.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Kernel intact** : `dag.sh` accepte les DAG hétérogènes (nœuds `craft:x`/`critique:x` mélangés aux
  nœuds gsd) et le `reopen` cross-métier rebloque les dépendants — prouvé T3/T4. Aucun script à modifier.
- **Rapports typés Pattern C** : les workers design rendent déjà le même bloc
  `{statut, findings, noeuds_debloques}` que les workers dev — le contrôle de flux du manager est
  réutilisable tel quel sur les étages croisés.
- **Gabarit d'allowlist** : `vf-test-orchestrator` porte déjà `Agent(vf-test-runner, vf-app-fixer)` —
  syntaxe et lint `check-agents.sh` existants.

### Established Patterns
- Doctrine en `references/` chargée on-demand + renvoi depuis l'agent (Phase 13 D-01) — jamais de
  doctrine longue en dur dans un agent.
- Tests = greps de doctrine dans les suites bash des modules (gabarit T15/T16, Phase 13 D-09).
- Bump par module : capacité → minor ; release racine + tag = validation humaine (Phase 13 D-10).

### Integration Points
- Le verrou de driver reste **au niveau mission** : les workers (crafter, judge, coder) n'acquièrent
  jamais le lock — seuls les managers le tiennent. Rien à changer, mais les doctrines doivent le dire
  explicitement pour les étages croisés.
- `vf-crafter`/`vf-design-judge` lisent la DA sur disque ; en mission dev le digest D-10 l'amortit.
- `vf-coder` invoque la chaîne gsd (discuss --auto → plan → execute → revue) — en étage design→dev,
  son entrée devient la spec du crafter : le mandat doit pointer la spec comme source du cadrage.

</code_context>

<specifics>
## Specific Ideas

- La granularité D-03 reprend mot pour mot la philosophie du kernel : « fait pour les missions, pas
  pour le quotidien » — l'étage design ne doit jamais devenir une taxe sur chaque étape.
- L'allowlist D-07 est le point de vigilance n°1 de la phase : recenser TOUS les dispatches réels de
  `vf-dev-manager` (y compris panels et chercheurs ADR-045) avant de la poser, sinon on casse des
  missions en production silencieusement.

</specifics>

<deferred>
## Deferred Ideas

- **Intégration « Claude Design »** (proposer, quand la DA manque, la création d'un DESIGN.md et/ou
  d'un design system complet via Claude Design connecté et lié au projet depuis Claude Code) —
  nouvelle capacité du design-orchestrator, sa propre phase. Noté pour le backlog roadmap. La Phase
  15 se limite à proposer DA-INIT (geste existant) comme next step.

</deferred>

---

*Phase: 15-collaboration-inter-quipes-dev-design*
*Context gathered: 2026-07-27*
