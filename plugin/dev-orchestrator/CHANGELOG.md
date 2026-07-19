# CHANGELOG — dev-orchestrator

## [v1.6.0] — 2026-07-19 (ADR-051)

Allowlist MCP des agents exécutants dérivée du lab — les sous-agents voient enfin les serveurs MCP
du projet (XcodeBuildMCP, mobile-mcp, DB métier…).

### Ajouté
- **`scripts/inject-mcp-tools.sh`** : injecteur idempotent. Lit les serveurs du `./.mcp.json` du lab
  et injecte `mcp__<serveur>__*` dans le `tools:` des agents flaggés `vf-mcp-consumer: true` (ou d'un
  fichier `--force`). Aucun nom de serveur ni d'agent en dur ; best-effort (python3/`.mcp.json`
  absents → no-op) ; `--dry-run`. Le glob `mcp__*` étant **refusé** en allowlist `tools:` (seul
  `disallowedTools` l'accepte), l'injection par-serveur est la seule voie générique.
- **`scripts/tests/test-inject-mcp-tools.sh`** : 10 cas (dossier, idempotence, `--force`, refus sans
  flag, no-op sans `.mcp.json`, hérite-tout, `--servers`, tri déterministe) — tous verts.
- **`agents/vf-coder.md`** : flag `vf-mcp-consumer: true` (exécutant : build/test).
- **`scripts/ensure-deps.sh`** : `patch_gsd_executor_mcp` — après l'install GSD, injecte les serveurs
  du lab dans `~/.claude/agents/gsd-executor.md` (`--force`, hors plugin). Re-jouable → auto-réparateur
  après une réinstall GSD.

### Note
- Le `tools:` d'un agent est lu au **démarrage de session** : **redémarrer Claude Code** après
  (ré)install pour que la nouvelle allowlist prenne effet.

## [v1.5.0] — 2026-07-09

Équipe manager de mission (pattern Reviz généralisé — spec 2026-07-09, ADR-046).

- **4 agents natifs** (`agents/`) : `vf-dev-manager` (sommet — planifie, décide via panels,
  distribue, contrôle de flux entre étages) + workers internes `vf-coder` (cycle d'étape),
  `vf-reviewer` (revue sans écriture), `vf-auditer` (audit sécu/dette sans écriture).
  Conformes ADR-044 ; workers `vf-internal: true` (Pattern 12).
- **Contrats de mission** (`references/mission-contracts.md`) : brief main→manager, rapport
  manager→main, signaux « mission », seuil `SEUIL_EQUIPE` — source unique (DRY).
- **Router** : détection de mission + proposition de l'équipe (heuristique 7, jamais d'office).
- **vf-auto** : aiguillage taille — court → boucle autonome inline, long → équipe.
- **Tests** : T8-T11 (conformité agents, contrats, routage, généricité).

## [v1.4.0] — 2026-07-08 (ADR-045)

### Ajouté
- **Recherche documentaire avant debug** (ADR-045), câblée dans trois briques :
  - `skills/vf-debug/SKILL.md` : **pré-étape obligatoire** avant la délégation à `gsd-debug` — si
    déclencheur (lib/framework/natif/version, ou fix déjà échoué), recherche context7 + issues
    GitHub d'abord, pistes priorisées et sourcées.
  - `AGENT.md` (`vibeflow-dev`) : la route « débugge » passe par le gate recherche-doc ; nouvelle
    heuristique de routage n°6 (le pilote a l'héritage web, il porte la recherche que les workers
    cloisonnés remontent via `doc-research-required`).
  - `references/autonomous-guardrails.md` : **6ᵉ garde-fou** « recherche doc avant debug empirique »
    + champ `maxResearchRoundsPerFlow` (défaut 2) au schéma `night-run.json` — la recherche précède
    les tentatives, ne consomme pas de slot `maxAttemptsPerFlow`, mais compte dans le budget global.
- Règle canonique référencée : `doc-research-before-debug` (module `software-architecture`).

## [v1.3.0] — 2026-07-08

### Ajouté
- **Routage des phases de design → `/vf-design`.** Nouvelle ligne dans la table de routage de
  `vibeflow-dev` (« design / UI / c'est moche / la DA / le style / refais l'écran / la typo /
  le spacing » → verbe `vf-design`, agent `vibeflow-design`) et dans le point d'entrée `vf-dev`.
  Un cycle de développement couvre désormais explicitement la phase de design sans quitter le
  vocabulaire VibeFlow.
- **Dépendance `design-orchestrator`** (`requires`) : le module design est **installé d'office**
  avec `dev-orchestrator`. Tout lab de développement dispose de `/vf-design` sans action
  supplémentaire (résolveur de deps transitif → `install --with-deps`).

## [v1.2.0] — 2026-07-07

### Ajouté
- **Verbe `/vf-decide`** — panel de décision pour trancher une zone grise technique (compare
  des options, produit un tableau comparatif sourcé + reco). Délègue au **mode advisor de
  `gsd-discuss-phase`** (qui orchestre le panel de recherche décisionnelle) — on route vers le
  skill canonique, jamais vers un agent en direct. Porte le total à **14 verbes `/vf-*`**. Ajouté
  à la table de routage de `vibeflow-dev` et à `vocabulary-map.md` (« advisor » → panel de décision).
- **Référence `references/autonomous-guardrails.md`** — doctrine des 5 garde-fous de boucle
  autonome (anti-thrash N=3, anti-régression revert, arrêt vert/plafond, séparation anti-triche,
  rapport de synthèse). Branchée sur `vf-auto` (section « Garde-fous (non supervisé) »). Extraite
  et généralisée depuis le track « équipe d'agents » (revizapp, couche B).

### Note
- La séparation anti-triche s'appuie sur le **Pattern 12 — Cloisonnement par outils**
  (module `reference`).

## [v1.1.0] — 2026-06-04

### Ajouté
- **Verbe `/vf-map`** — cartographie d'un code existant (délègue à `gsd-map-codebase`),
  construit selon la discipline `writing-skills`. Complète `vf-init` (bootstrap + démarrage
  projet) pour couvrir explicitement le parcours « projet existant ». Porte le total à
  **13 verbes `/vf-*`**.
- README : section Usage enrichie — routage NL init/map, parcours types (premier contact,
  projet existant, tâche rapide, autonomie), verbe `vf-map`.

### Corrigé
- `test-dev-orchestrator.sh` portable : détecte la disposition source (`AGENT.md` + `references/`
  à la racine) vs lab installé (`agents/dev-orchestrator.md` + `agents/<mod>-references/`, D7).
  Le test shippé ne produit plus de faux échecs quand il est lancé depuis un lab.

## [v1.0.0] — 2026-06-04

### Module initial complet (5 plans, phase 01-dev-orchestrator)

**Squelette du module**
- Structure conforme aux modules vibeflow-os (`VERSION`, `CHANGELOG.md`, `README.md`, `references/`, `scripts/`)
- Type : agent + multi-skills + scripts (orchestrateur de développement)

**Index auto-généré (D4 — anti-hallucination)**
- Script `build-gsd-index.sh` qui génère `references/gsd-skills-index.md` à partir des skills GSD réellement installés (`~/.claude/skills/gsd-*`)
- Aucun nom de skill écrit en dur : extraction factuelle du frontmatter (`name` + `description`)
- Contrat de sortie `VF_INDEX_OUT` surchargeable (consommé par le hook post-install, D7)
- Idempotent : ré-exécution = régénération complète (IDX-02)

**Agent routeur (Plan 03)**
- `AGENT.md` (`vibeflow-dev`, ≤250L) : routage langage naturel → action, 14 cibles distinctes
- Doctrine pipeline déportée `references/GSD-PIPELINE.md` (chargée on-demand)
- Ne nomme jamais GSD/Superpowers ; reframe en vocabulaire VibeFlow

**Couche d'abstraction (Plan 04)**
- 12 verbes `/vf-*` thin delegators (construits via `writing-skills`)
- `references/vocabulary-map.md` (traduction GSD → VibeFlow)

**Bootstrap + intégration (Plan 02 & 05)**
- `ensure-deps.sh` : auto-install non-interactif idempotent de GSD + Superpowers, fallback manuel
- `vibeflow-update.sh` étendu : copie des references d'un module agent sous `.claude/agents/<mod>-references/` (D7) + hook post-install régénérant l'index (IDX-02)
- Suite `test-dev-orchestrator.sh` (4 axes VERIF-01 + densité `wc -l` VERIF-02)
