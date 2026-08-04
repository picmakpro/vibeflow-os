# CHANGELOG — design-orchestrator

## [v1.4.1] — 2026-08-04 (`effort:` par rôle sur les 4 fichiers d'agents, Phase 24)

### Modifié
- **Les 4 fichiers d'agents du module déclarent `effort:`** — `AGENT.md` (`vibeflow-design`)
  **high**, `vf-design-manager` **high** et `vf-design-judge` **high** (pilotage et jugement) ;
  `vf-crafter` **medium** (exécution). Barème par rôle repris des agents-templates de
  `plugin/reference/`, qui ont été **lus, jamais modifiés**.
- Motif : `check-agents.sh` **exige** désormais le champ (conductor v1.20.0) au lieu de le valider
  seulement quand il est présent. Le module est concerné par **les deux** familles d'agents que
  l'installeur pose — `agents/<nom>.md` et l'`AGENT.md` de la racine — d'où 4 fichiers et non 3.

## [v1.4.0] — 2026-07-31 (geste documentaire en mission design, Phase 22)

**`vf-design-manager` n'avait aucun geste documentaire. Il pose désormais le même nœud `docs`
agrégé que son homologue dev, en fin de mission — par renvoi, jamais par copie.**

### Ajouté
- **§Hygiène documentaire** dans `vf-design-manager` (161 → 187 lignes) : le nœud `docs` agrégé,
  posé une seule fois en fin de mission (`deps` = tous les nœuds de craft et de critique), sur les
  **mêmes quatre déclencheurs** que côté dev — surface publique touchée, signal `[doc-drift]`
  actif, nouveau module ou nouvelle capacité — sous le même régime superviser/autonome.
- **Renvoi cross-module vers la doctrine hébergée dans `dev-orchestrator`**
  (`dev-orchestrator-references/docs-flow.md` §Déclencheurs et §Garde-fous) : **aucune copie
  locale**. La table des quatre déclencheurs et la doctrine des trois régimes de confirmation
  n'existent qu'à un seul endroit ; `vf-design-manager` porte les noms, pas la table (ADR-057,
  même patron que le renvoi déjà en place vers `mission-cross-team.md`).
- **Bloc T23** de `test-dev-orchestrator.sh` (`dev-orchestrator`) : le câblage des deux managers
  est désormais non-régressable, avec `SKIP` explicite si ce module design est hors du périmètre
  scanné.

### Non modifié (volontaire)
- **Le gate `DESIGN.md` reste distinct et inchangé** : la bible visuelle (tokens, palette, typo,
  perso) n'est pas de la doc produit, et le nouveau nœud `docs` ne s'y confond jamais.
- **Le frontmatter de l'agent n'a pas bougé** : `Skill` y était déjà présent, aucune capacité
  d'outillage nouvelle n'était nécessaire pour poser ce geste documentaire.

Référence : `.planning/phases/VFDO-22-hygi-ne-documentaire-doctrine-de-sortie-et-captation-d-inten/`.

## [v1.3.2] — 2026-07-31 (barrière d'écriture réelle de `vf-design-judge`, Phase 20)

### Corrigé
- **`vf-design-judge` porte `disallowedTools: Write, Edit`** : la barrière d'écriture était une
  simple absence dans `tools:`, rouverte silencieusement au runtime par `memory: project`. Elle
  devient une contrainte posée par le frontmatter.
- **La description et le corps de l'agent cessent d'affirmer une barrière complète qu'il n'a pas** :
  `vf-design-judge` est le seul des 4 juges du team-kernel à conserver `Bash` (inspection du
  rendu) ; le fait exact est désormais écrit — canal shell conservé, retenue sur ce canal comme
  engagement de prompt, pas une barrière.
- **`vf-design-manager` cite le mécanisme réel** (au lieu du seul adjectif « read-only ») pour
  justifier le dispatch parallèle de son juge — sans prétendre à une barrière complète que
  `vf-design-judge` n'a pas.

Référence : `plugin/conductor/references/team-kernel.md` §Cloisonnement par tools,
`.planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/`.

## [v1.3.1] — 2026-07-28 (isolation de branche des missions d'équipe, ADR-059)

`vf-design-manager` applique la même règle que le manager dev : **branche dédiée avant le premier
commit, PR ouverte à la fin, jamais de merge** — le merge appartient à l'utilisateur (ADR-031). Le
protocole, les conventions de nom et les cinq replis (pas de dépôt git, pas de remote, `gh` absent,
arbre sale = halt condition, `CLAUDE.md` du projet cible qui prime) vivent en un seul endroit :
`dev-orchestrator/references/mission-contracts.md` §Isolation de branche — pas de duplication.

Fichier : `agents/vf-design-manager.md` §Garanties.

## [v1.3.0] — 2026-07-27 (étage implémentation croisée, Phase 15)

### Ajouté
- **Étage implémentation** : `vf-design-manager` peut désormais dispatcher `vf-coder` en aval
  du craft, en opt-in par brief (`livrable: specs+implementation`) — la spec produite par
  `vf-crafter` sert de cadrage à l'implémentation, avec double juge parallèle
  (`vf-design-judge` re-score le rendu ∥ `vf-reviewer` relit le diff) et budgets séparés 3+3
  tours par écran. Comble le trou « specs jamais implémentées ». Porte aussi la recherche
  documentaire ADR-045 pour `vf-coder`, qui n'a pas d'accès web.
- Allowlist `Agent(...)` de `vf-design-manager` portée à 6 noms ; descriptions de
  `vf-crafter`/`vf-design-judge` élargies au dispatch par les deux managers.
- Suite de tests : T8/T8b (allowlist, doctrine d'étage implémentation croisée) + T4 durci.

## [v1.2.2] — 2026-07-26

### Modifié
- README monté au standard de doc (installation, démarrer, usage, référence).

## [v1.2.1] — 2026-07-26

### Corrigé
- `requires` += `conductor` : le manager design consomme le team-kernel (dag.sh/driver-lock.sh) — dépendance non déclarée depuis l'extraction v2.34.0.

## [v1.2.0] — 2026-07-25 (équipe de mission design — team-kernel)

### Ajouté

- **Équipe de mission design** (`agents/`) — première instanciation NON-dev du team-kernel
  (`conductor-references/team-kernel.md`) : `vf-design-manager` (opus — plan de bataille en DAG,
  lock de driver, dispatch parallèle sur écrans disjoints, digest ≤ 30 lignes, contrôle de flux
  sur rapports typés, halt conditions), `vf-crafter` (sonnet, interne, sans Task — production
  d'UN écran via la chaîne d'outils design, specs + tokens multi-stack) et `vf-design-judge`
  (sonnet, interne, sans Write/Edit — critique scorée /100 : conformité DA /40 + 6 dimensions
  /10). « Vert » design = score ≥ 70/100 ; 3 tours max de craft→re-critique par écran.
- **Heuristique de proposition** dans `AGENT.md` : sur signal mission design (multi-écrans,
  refonte complète, « toute l'app »), `vibeflow-design` PROPOSE `Task(vf-design-manager)` —
  jamais d'office ; écran unique → routage direct inchangé.
- **Suite de tests** `scripts/tests/test-design-orchestrator.sh` : présence + conformité des
  3 agents (check-agents --strict), cloisonnement par tools (Pattern 12), densité ADR-029,
  câblage kernel (dag/driver-lock/digest/seuil) et heuristique de routage.

## [v1.1.1] — 2026-07-25

### Modifié
- Suit la bascule agentique du dev-orchestrator v2.0.0 : les renvois vers les verbes dev supprimés pointent vers les briques gsd réelles ; le reframe dev est abandonné, la table de vocabulaire ne gouverne plus que la chaîne design.

## [v1.1.0] — 2026-07-25 (verbe `/vf-sketch` + démarcations croisées)

### Ajouté

- **Verbe `/vf-sketch`** (`skills/vf-sketch/`) — maquette jetable : « maquette-moi ça », « montre-moi
  à quoi ça ressemblerait », « esquisse deux ou trois variantes ». Délègue à l'outil de maquettage
  interne. C'est le **seul** geste design qui gagne une porte d'entrée propre, parce que
  l'utilisateur le formule spontanément ; le contrat UI et la revue UI restent routés en interne
  depuis `/vf-design`.

### Modifié

- **Description de `/vf-design`** réécrite sur le gabarit commun (formulations réelles,
  contre-exemples nommant les voisins, portée d'invocation) : le jetable **visuel** va à
  `/vf-sketch`, le jetable **fonctionnel** à `/vf-spike`, la construction à `/vf-execute`.
  Réciproquement, `/vf-sketch` repousse vers `/vf-design` et `/vf-spike`.
- **Corps de `/vf-design`** : il nomme désormais la chaîne interne qu'il porte (contrat UI, revue
  UI), qui n'a pas de verbe dédié — un test d'exhaustivité vérifie qu'aucune cible n'est promise
  par la doctrine de routage sans être réellement citée par le verbe qui la porte.
- **Vocabulaire** : le module ne parle plus d'« idéation » pour son exploration de directions
  visuelles — le mot appartient au verbe `/vf-explore` du module dev.

## [v1.0.0] — 2026-07-08

### Module initial

**Squelette du module** (conforme aux modules vibeflow-os : `VERSION`, `CHANGELOG.md`,
`README.md`, `module.json`, `AGENT.md`, `skills/`, `references/`)
- Type : **agent + skills**. Installé d'office avec `dev-orchestrator` (via ses `requires`).

**Agent routeur `vibeflow-design`** (`AGENT.md`, ≤250L, ADR-044 : description + model + memory)
- Table de routage langage naturel → geste design coulisse (DA-INIT / DESIGN-WORKFLOW par intent
  ACTION / INSPIRATION / CRITIQUE / craft ciblé).
- **Généricité multi-stack** : détection de stack, incarnation du système de design adaptée
  (web CSS/Tailwind · SwiftUI · React Native / Flutter · desktop). Produit des specs + tokens,
  jamais du code framework-locké.
- Doctrine : DA avant refonte, diagnostic avant geste, vérification après craft.
- Reframe systématique ; ne nomme jamais les outils design bruts.

**Verbe `/vf-design`** (`skills/vf-design/`)
- Thin delegator à description riche en wording (auto-invocation langage naturel), délègue à
  `vibeflow-design`. Point d'entrée design unique.

**Références on-demand** (`references/`)
- `DESIGN-WORKFLOW.md` — workflow quotidien (routing intent + complexité QUICK FIX / PLAN MODE /
  FULL DESIGN, checklists par mode, gate de sortie), générique multi-stack.
- `DA-INIT.md` — initialisation de la direction artistique (bible visuelle + section CLAUDE.md +
  système de design incarné selon la stack).
- `design-toolchain.md` — mapping reframe → plugins réels (`ui-ux-pro-max`, `frontend-design`,
  `impeccable`, `superpowers`), vérification de présence et **dégradation gracieuse**.
- `design-vocabulary-map.md` — table de reframe (outils design → vocabulaire VibeFlow).
- `templates/DESIGN.md` + `templates/CLAUDE-design-section.md` — templates génériques (rôles
  stables, incarnation selon stack).

### Origine
- Dérivé et généralisé depuis le kit `design-system-kit` (skills `design` + `design-init-da`,
  initialement Next.js/Tailwind/shadcn) — rendu **stack-agnostique** et aligné sur la doctrine
  VibeFlow (agent routeur + verbe thin + références on-demand + reframe).
