# CHANGELOG — design-orchestrator

## [v1.5.3] — 2026-08-28 (bootstrap multi-runtime — chaîne d'outils design dispatchée par runtime, RUNT-01/02)

**Patch** (durcissement, comportement observable modifié uniquement sur un poste Codex ou sans
CLI `claude` détectée) :

- **`ensure-design-deps.sh`** : les 5 sites CLI-couplés de `detect_all()` (S1 JSON, S2 awk texte)
  et `process_plugin()` (`enable`, `marketplace add`, `install`) routent désormais par
  `plugin/_internal/runtime-cli-dispatch.sh` au lieu d'un `command -v claude`/`claude plugin`
  figé. Sur `claude` ou `codex`, le geste RÉEL (activation/install/marketplace) s'exécute — même
  grammaire d'arguments. Sur un runtime non détecté ou non supporté (OpenCode/kimi-code, non
  mesurés), dégradation DÉCLARÉE (étape manuelle par plugin, exit propre) — jamais un échec
  silencieux. La machine à états S1 JSON / S2 awk texte de `detect_all()` est INTÉGRALEMENT
  conservée : seul le sous-processus invoqué change, jamais le parsing de sa sortie.
  `CLAUDE_AVAILABLE`/`INDETERMINE` se généralisent en `RUNTIME_AVAILABLE`/`INDETERMINE`, sémantique
  inchangée.
- Repli inchangé si le script partagé est introuvable (poste pas encore mis à jour) :
  comportement `claude`-figé ACTUEL, aucune régression (T9e mis à jour pour reconnaître cette
  exception SANCTIONNÉE — un artefact partagé de l'engine, pas « un autre module » au sens D-04 —
  sans affaiblir la garde d'autonomie sur toute autre résolution).

## [v1.5.2] — 2026-08-17 (Phase 32, doctrine du verrou resynchronisée)

**Patch** (doctrine d'agent corrigée pour rester exacte, aucune nouvelle capacité).

- `vf-design-manager.md` : le couple `acquired:false`/`recovered:true` décrit comme chemin
  nominal d'`acquire` sur un lock périmé — obsolète depuis les plans 32-01/32-02 — est remplacé
  par la doctrine réelle post-Phase 32 : `acquire` REFUSE (`reason: stale-requires-takeover`,
  champ `hint`) et nomme les verbes explicites `takeover --owner=<id> --step=<mission design>`
  (reprise d'un lock périmé) et `reclaim --owner=<id>` (rattachement de session sur un lock encore
  vivant). Renvoi à `conductor-references/team-kernel.md` pour la doctrine complète et la
  convention `Fence:` (LOCK-05).

## [v1.5.1] — 2026-08-10 (correctif #38 — `isolation: worktree` retiré du frontmatter)

**Retrait d'`isolation: worktree` du frontmatter de `vf-crafter`.** Livrée en v2.49.0
(Phase 27), la ligne rendait le worker de production design inutilisable dès qu'un manager mandatait une branche autre
que la branche par défaut : le worktree du harness fork depuis la **branche par défaut**, jamais
depuis le HEAD courant — il atterrissait sur une branche technique **sans aucun fichier du
mandat**, se déclarait bloqué sans produire, et le manager se rabattait silencieusement sur un
agent générique dépourvu de sa doctrine et de ses allowlists.

La précondition qui corrige le fork — `worktree.baseRef: "head"` — vit dans le settings du poste
et **n'est posée nulle part par l'engine** : elle avait été posée dans le settings local du repo
de développement, et les agents ont été distribués sans elle. Même corrigée, elle ne suffirait
pas : rien ne ramène les commits du worker vers la branche de mission (`open-gsd/gsd-core#3302`).

L'isolation redevient ce que la doctrine du kernel dit déjà qu'elle est — une **décision de
dispatch du manager**, jamais une propriété du worker. Désormais machine-enforced :
`check-agents.sh` refuse `isolation:` dans un agent distribué.

Référence : issue #38.

## [v1.5.0] — 2026-08-10 (auto-install de la chaîne d'outils design)

**La détection existante du repo était aveugle à l'état enabled/disabled : un plugin de la
chaîne design installé puis désactivé passait pour présent, sans jamais le signaler.**
`claude plugin list | grep <nom>` (seule détection outillée précédente, héritée de
`dev-orchestrator/scripts/ensure-deps.sh`) matche sur le nom seul — il ne regarde jamais le
champ d'activation.

### Ajouté
- **`scripts/ensure-design-deps.sh`** — bootstrap autonome (D-04 : aucune dépendance
  d'exécution vers `dev-orchestrator`) qui vérifie **présence ET activation** des 4 plugins
  de la chaîne design (`superpowers`, `ui-ux-pro-max`, `frontend-design`, `impeccable`).
  Source structurée retenue : `claude plugin list --json` (parsée via `python3`, garde ADR-054),
  avec repli `awk` sur la sortie décorée si la CLI est trop ancienne. `installed_plugins.json`
  écarté délibérément : il ne porte AUCUN champ `enabled` — c'est l'origine même du trou fermé
  ici. Un plugin désactivé reçoit un `claude plugin enable … --scope …` scopé, **jamais** un
  `install` nu ; un plugin actif sur au moins un marketplace parmi plusieurs entrées du même nom
  compte comme présent (cas réel mesuré : `frontend-design` à la fois désactivé sur
  `claude-code-plugins` et actif sur `claude-plugins-official`).
- **Câblage double** : hook post-install nommé dans `plugin/_internal/vibeflow-update.sh`
  (double garde `-f` source+cible, best-effort — D-03a, ne fait jamais échouer l'install d'un
  module) ; section « Premier contact — chaîne d'outils (best-effort) » dans `AGENT.md`, lancée
  une fois par session avant DA-INIT/DESIGN-WORKFLOW, avec le garde-fou d'Iron Law explicite
  (la sortie du script ne remonte jamais telle quelle à l'utilisateur).
- **Flag `--quiet` et contrat de non-silence.** Le script écrit tout sur stderr et distingue la
  ROUTINE (bannière, « déjà actif », résumé tout-vert — supprimée par `--quiet`) de l'ANOMALIE
  (plugin absent ou désactivé, geste réellement exécuté, étape manuelle, résumé dès qu'un plugin
  n'était pas déjà actif — qui traverse toujours `--quiet`). Le hook de l'engine appelle donc
  `--quiet` **sans** `2>&1` : avaler stderr y aurait rejoué, un cran plus haut, la dégradation
  silencieuse que cette version ferme — une install aurait pu ne poser aucun outil design sans
  qu'une seule ligne l'indique.
- Bloc T9..T9g dans `scripts/tests/test-design-orchestrator.sh` (aucun nouveau fichier de suite
  — compteur racine inchangé, 52) : idempotence, scope, le cas de la tâche (D-02, stub
  `claude plugin list --json`), dégradation CLI absente, autonomie D-04, câblage double, et
  non-silence (muet à vide / parlant sur anomalie / hook qui n'avale pas stderr).

### Hors périmètre assumé
- **Aucun contrôle de version/fraîcheur** des 4 plugins : la moitié porte une version `unknown`,
  un contrôle serait du bruit. `design-toolchain.md` §Vérification de présence documente le
  contrat à trois points et reste jumelle de la table littérale du script.

Référence : `.planning/quick/260810-fh3-doter-design-orchestrator-d-un-ensure-de/`.

## [v1.4.2] — 2026-08-10 (armement worktree du groupe A)

### Modifié
- **`vf-crafter` armé `isolation: worktree`** (Phase 27, groupe A) — écritures isolées par
  worktree, mémoire d'agent embarquée via `.worktreeinclude`. Précondition de sûreté :
  `worktree.baseRef: "head"`.

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
