# Changelog — conductor

## [v1.11.3] — 2026-07-20 (audit robustesse hooks — 2e vague, gate agents fiabilisé)

### Corrigé
- **`check-agents.sh` (parseur YAML minimal → 2 faux positifs bloquants + 1 contournement)** :
  scalaires quotés (`name: "x"`, parfois OBLIGATOIRES en YAML) rejetés « invalide » → déquotage ;
  `description:` en plain scalar multi-ligne perdue (« champ requis manquant ») → typage différé ;
  `skills:` en chaîne plate (`skills: a, b`) sautait silencieusement TOUT le gate anti-hallucination
  même en `--strict` → normalisation en liste. BOM UTF-8 toléré (`utf-8-sig`).
- **`guard-agent-write.sh`** : anti-trappe fail-closed — un crash interne du checker (rc≠0 SANS
  diagnostic ✗) produisait un deny générique sur un agent conforme → désormais fail-open ;
  portée restreinte au LAB COURANT (en install user-scope, un agent perso `~/.claude/agents` ou
  un autre projet n'est plus soumis à la doctrine du lab) avec `realpath` des deux côtés
  (piège symlink macOS /var→/private/var) ; `--skills-dir` dérivé du lab CIBLE du file_path
  (verdict indépendant du CWD du hook) ; limites assumées documentées en tête.
- **`check-debug-research.sh`** : filet de signature resserré — `crash-free` (KPI mobile) et
  `diagnos` isolé (« Diagnostique la santé du funnel », « pass/fail + diagnostic ») ne sont plus
  du dépannage (`diagnos` exige une co-occurrence bug/erreur/panne) ; la brique livrée
  `vf-test-runner` (mobile-test-team) n'est plus flaguée à chaque SessionStart.
- `check-plugin-update.sh` : verrou mkdir (stale 300s) contre les instances parallèles, bornes
  réseau `http.lowSpeedLimit/Time` (TCP qui rampe > 1 min sinon), écriture du cache atomique.

### Tests
- `test-check-agents.sh` 14 → 20 (quotes, multi-ligne, skills chaîne + --strict, BOM, crash
  checker → fail-open, hors-lab → allow) ; `test-check-debug-research.sh` 9 → 12 (crash-free,
  diagnostic métier, dogfood briques mobile-test-team contre le linter livré).

## [v1.11.2] — 2026-07-20 (audit robustesse hooks)

### Corrigé
- **`update-banner.sh` : le rafraîchissement du cache était MORT sur macOS** — `setsid` n'existe
  pas sur macOS et son échec (127) en arrière-plan est asynchrone : le pattern
  `( setsid … & ) || fallback` sortait toujours 0 → le fallback ne se déclenchait jamais → cache
  jamais rafraîchi (démontré : cache local figé au 12/07). Désormais : `command -v setsid` testé
  AVANT, stdin fermé (`</dev/null`). Vérifié e2e : cache réécrit avec données fraîches.
- `check-plugin-update.sh` : `GIT_TERMINAL_PROMPT=0` sur le `ls-remote` — un repo privé sans
  credential helper échoue proprement au lieu de pendre sur un prompt en tâche de fond.
- `guard-agent-write.sh` : préfiltre pur-bash avant python3 (~6ms vs ~90ms sur tout Write sans
  rapport avec `.claude/` — le hook tourne sur CHAQUE Write du lab ; surensemble strict justifié
  en commentaire) ; frontière de chemin exacte (`my.claude/agents` ne matche plus — même classe
  de faux positif que consolidator CSL-12) + `normpath`.

## [v1.11.1] — 2026-07-19 (ADR-051)

### Ajouté
- **`check-agents.sh`** : `vf-mcp-consumer` ajouté au set `KNOWN` des champs frontmatter reconnus —
  le flag qui marque un agent exécutant recevant l'allowlist MCP dérivée du lab (ADR-051) n'est plus
  signalé « champ inconnu ». Le sélecteur `vf-mcp-consumer` EST le point d'enforcement de l'injection
  (data-driven, aucun nom d'agent en dur).
- **`skills/vf-calibrate`** : étape « ré-affirmer l'allowlist MCP » — quand le `./.mcp.json` du lab
  gagne/perd un serveur **sans** bump de module, re-jouer `inject-mcp-tools.sh` (agents flaggés +
  `gsd-executor`). Rappel du redémarrage de session requis.

## [v1.11.0] — 2026-07-16 (ADR-048 — orchestrateur métier systématique)

### Ajouté
- `vf-new-lab` Phase 7 **point 5bis** : dès **≥2 agents métier**, pose d'office un **orchestrateur métier**
  (copie verbatim du skill `metier-orchestration` + instanciation de `orchestrator-template.md` parametré
  au métier). Seuil < 2 → pas d'orchestrateur ; métier = code → rôle tenu par `dev-orchestrator` (pas de doublon).
- `references/bootstrap-method.md` : règle de dérivation « ≥2 agents → orchestrateur métier » + exemple mis à jour.

### Corrigé
- Renvoi circulaire : les bundles pointaient « l'orchestration » vers le conductor, qui ne fait pas le travail
  métier. L'orchestration métier est désormais portée par l'orchestrateur métier posé ; le conductor reste méta.

## [v1.10.0] — 2026-07-11 (ADR-047 — skill-creator dans la baseline)

### Ajouté
- `module.json` : **`skill-creator` ajouté aux `requires`**. C'est l'outil que `vf-new-lab` invoque
  en Phase 5 (fan-out `subagent_type: skill-creator`) et que le Gate C exige pour créer un skill
  manquant. Il est le **canal unique de création de skills** (« Sole authorized channel for skill
  creation ») — donc une **dépendance dure** du conductor, au même titre que `validator`. Comme le
  conductor est `mandatory`, `skill-creator` est désormais **posé d'office à chaque install** (sa
  fermeture transitive est tirée par `--with-deps`), avant toute création de lab.

### Corrigé
- Régression silencieuse : `vf-new-lab` fanned out vers un `subagent_type: skill-creator` **jamais
  installé** (absent de `requires` ET de la liste « Typiquement » de la Phase 7). Les skills du lab
  étaient donc soit non fabriqués, soit rédigés à la main hors pipeline (perte de l'eval/qualité).
- `vf-new-lab` Phase 7 (point 2) : `skill-creator` ajouté à la liste des modules typiques + garde-fou
  explicite « jamais rédiger un skill à la main — canal unique skill-creator, même pour une procédure
  interne ». `installer/SKILL.md` : récap d'exemple de la fermeture du conductor mis à jour.

## [v1.9.0] — 2026-07-08 (ADR-045)

### Ajouté
- **Lint `scripts/check-debug-research.sh`** : gate déterministe de la présence d'une phase de
  recherche documentaire avant debug dans les briques de dépannage d'un lab (ADR-045). Même contrat
  que `check-agents.sh` : `--strict` / `--hook` / `--file`, symboles `✓ ✗ ⚠`, exit 0/1, fail-open
  si `python3` absent. Consommé par le `vibeflow-validator` en Phase 2 et branché en advisory
  SessionStart (`--hook || true`) dans `hooks/hooks.json`.
- Suite de tests `scripts/tests/test-check-debug-research.sh` (9 cas, tous verts).

## [v1.8.2] — 2026-07-07

### Corrigé
- Engine d'update (`vibeflow-update.sh`) : `update --all` (donc `/vf-update`) **garantit
  désormais la baseline obligatoire** (INST-02a). Un module `mandatory` publié après la
  configuration d'un lab — typiquement `conductor` lui-même sur un lab antérieur à v2.13.0 —
  était **ignoré à vie** : `update --all` n'itérait que sur le registre `.vibeflow-installed`,
  donc ni les scripts ni les hooks du module manquant n'étaient posés. Conséquence directe :
  le **bandeau de mise à jour** (`update-banner.sh`, SessionStart) ne pouvait jamais s'afficher.
  Nouvelle fonction `ensure_mandatory_baseline` : installe la fermeture transitive des modules
  `mandatory` absents (data-driven via `module.json`, **aucun nom de module en dur**).

### Durci
- `update <module>` sur un module **déjà à jour** re-synchronise désormais sa gouvernance
  (re-pose les scripts + re-merge les hooks, idempotent) au lieu de sortir tôt (`return 0`) —
  `/vf-update` devient auto-réparateur si un `hooks.json` a dérivé sans bump de `VERSION`.
- Tests : `test-vf-update.sh` couvre la baseline `mandatory` (module absent rattrapé + closure)
  et la resync gouvernance (hook re-mergé à version inchangée). Extraction DRY de
  `copy_module_scripts` (partagée entre install et resync).

## [v1.8.1] — 2026-07-07

### Corrigé
- Skill `vf-update` : la couche plugin utilise désormais l'**identifiant complet**
  `claude plugin update vibeflow@vibeflow-os` (le nom nu peut échouer par « Plugin not found »
  quand le cache de catalogue est périmé) + parade documentée (`marketplace update` / purge du
  `plugin-catalog-cache.json`). Constaté en conditions réelles lors du premier update 2.4.1 → 2.19.0.

## [v1.8.0] — 2026-07-07

### Ajouté
- **Mise à jour du plugin en un geste** — commande `/vf-update` + skill `vf-update`.
  - `check-plugin-update.sh` — compare la version installée (`installed_plugins.json`) au **dernier
    tag GitHub** (`git ls-remote --tags`, source de vérité depuis la discipline de tags), écrit un
    cache `~/.cache/vibeflow/update-check.json`.
  - `update-banner.sh` — hook **SessionStart** : signale « mise à jour disponible X → Y, lance
    /vf-update » depuis le cache, puis rafraîchit le cache en tâche de fond. Câblé dans `hooks.json`.
  - `vf-update-run.sh` — re-matérialise les modules installés depuis le **cache le plus récent**
    (localisé lui-même, car la session courante garde l'ancien `${CLAUDE_PLUGIN_ROOT}`).
  - Le skill orchestre les **deux couches** sous confirmation (ADR-031) : `claude plugin update
    vibeflow` (marketplace) puis engine `update --all` (modules), + rappel de redémarrage.
  - Tests : `test-vf-update.sh` (bandeau + sélection semver du cache) — 4/4.

## [v1.7.0] — 2026-07-07

### Ajouté
- Convention **`vf-internal: true`** (Pattern 12) : un worker interne le déclare dans son frontmatter.
  - `generate-agent-commands.sh` — le sweep **saute** ces agents : aucune commande d'incarnation
    `/<worker>` exposée à l'utilisateur (un worker dispatché uniquement par un orchestrateur n'a
    pas à être invocable en direct). Le mode `--agent` explicite reste inchangé.
  - `check-agents.sh` — `vf-internal` ajouté aux champs connus (plus de warning « champ inconnu »).

## [v1.6.0] — 2026-07-05 (ADR-044 — agents natifs machine-enforced)

### Ajouté
- `check-agents.sh` — lint machine de la conformité NATIVE des agents (.claude/agents/*.md) :
  frontmatter présent, name/description/model/memory requis, enums valides (référentiel doc
  officielle 2026-07-05), skills déclarés EXISTANTS (--strict), champs inconnus signalés (typos),
  BUDGET DE PRÉCHARGEMENT (skills: injecte le SKILL.md entier au startup — warn > 200L/skill,
  erreur > 1200L cumulées VF_PRELOAD_MAX, erreur si disable-model-invocation, warn si context:fork).
- `guard-agent-write.sh` — hook PreToolUse(Write) : un agent non natif ne peut plus être ÉCRIT
  dans .claude/agents/ (deny avec erreurs précises + squelette canonique).
- `hooks/hooks.json` — guard Write + check-agents SessionStart posés automatiquement à l'install.
- vf-new-lab Phase 7 : squelette frontmatter canonique OBLIGATOIRE (point 5) + règle de chargement
  du contexte (précharger ≤ 200L systématiques, on-demand sinon) + format de retour standard et
  pont d'escalade C4 dans le body de chaque agent + **Gate C étendu** (check-agents --strict).

### Décision
- contracts.md n'est PAS posé à l'init (pas un mécanisme runtime — sa valeur, format de retour +
  escalade, vit dans le body des agents et pointe vers conductor-references/contracts.md).

### Tests
- `test-check-agents.sh` (14 : lint 10 + guard 4).


## [v1.5.0] — 2026-07-04 (ADR-043)

### Ajouté
- vf-new-lab Phase 7 **GATE C — Conformité machine (BLOQUANT)** : l'init ne se conclut pas sans
  `check-registres.sh --strict` exit 0 + hooks de gouvernance présents dans settings.json.
- Phase 7 point 4 : après pose des registres, indexation par la machine
  (`reindex.sh --all --apply`) — jamais d'index rédigé à la main.

### Modifié
- Canon DECISIONS.md/DEC-XXX (references/contracts.md).

## v1.3.0 — 2026-06-24

`vf-new-lab` évolue en **Lab Factory clarification-first** (pipeline 7 phases). L'init ne pose plus un
squelette : elle clarifie en profondeur (gate machine-enforced), dérive un manifeste de capacités, et
**fabrique** les skills + auditeurs. Rétrocompatible (toujours invocable « crée un lab »), profondeur
adaptative au profil.

### Ajouté
- **Clarification-first** : Phase Triage (greenfield/brownfield + profil adaptatif) → Scan brownfield
  (explorer) → élicitation section par section avec **menu numéroté** (pattern BMAD) → **Gate A**
  (`[À CLARIFIER]` bloquant sur `LAB_BRIEF.md`). Refs `elicitation-methods.md` + `completeness-gate.md`.
- **T2 — Manifeste de capacités** : dérive les capacités (savoir/compétence/procédure), **Gate B**
  (justification obligatoire), proportionnalité au profil. Ref `capability-manifest.md` +
  `scripts/proportion-capabilities.sh` (tests 9/9).
- **T3 — Fan-out skill-creator** : fabrication parallèle (N × skill-creator, un par capacité P0) +
  anti-slop (gate capacité + eval par skill + critique de complétude). Ref `skill-fanout.md`.
- **T4 — Ficelage auditeurs** : un auditeur par procédure générative via `audit-architecture` (verdict
  bloquant). Ref `procedure-audit-wiring.md`.
- **T5 — Assemblage** : agents câblés sur les skills fabriqués, planning v2 compartiments, 5 registres
  (dont EVALS), garde-fous, stamp. Récap adaptatif (pédagogique en mode découverte).

## v1.2.0 — 2026-06-23

Câblage de la **topologie à compartiments** (planning-core v2.0.0) dans l'init, l'update et le pipeline.

### Ajouté / Modifié
- `vf-new-lab` : étape de dérivation « topologie du lab » (mono-objectif vs compartiments) + typage
  `deliverable`/`continuous`/infra + seuil d'autonomie ; scaffolding *steering lab + INDEX + plan par
  compartiment qualifié*. Garde-fou « jamais un `.planning/` par compartiment systématique ».
- `vf-calibrate` : cas **planning v2** (breaking-doctrine) routé vers la recette de migration sans perte.
- `references/migration-playbook.md` : recette **§2bis migration planning v2 sans perte de données**
  (détection de dette → typage → récupération de l'existant en `_archive/` → désengorgement mémoire → INDEX).
- `references/conductor-pipeline.md` : étape compartiments + garde-fou transverse.

## v1.1.0 — 2026-06-11

`vf-new-lab` rendu **bundle-aware** + correction d'un pointeur cassé.

### Corrigé
- Pointeur cassé : `vf-new-lab` référençait `references/bootstrap-method.md` (introuvable au runtime
  car le skill et les references s'installent à des emplacements distincts) → pointe désormais vers
  `.claude/agents/conductor-references/bootstrap-method.md` (emplacement réel d'install).

### Ajouté
- Mode bundle métier : si un bundle est installé (`docs/<metier>-bundle/`), `vf-new-lab` lit son
  `content/BUNDLE.md` et **instancie** les blueprints `content/agents/*.blueprint.md` au lieu de
  dériver de zéro — le châssis conforme est déjà porté par le bundle. Compatible business-pilot /
  content / growth.

## v1.0.0 — 2026-06-11

Release initiale. Agent méta orchestrateur central + gardien du framework, distribué dans chaque lab.
Comble 4 trous identifiés à l'audit du plugin (cf. README).

### Ajouté
- **Agent `vibeflow-conductor`** (AGENT.md, ≤250L) — porte d'entrée méta pour configurer/vérifier/
  mettre à jour/migrer un lab. Route et délègue (installeur, validator, planning-core, consolidator).
  4 rôles : configurateur / vérificateur / calibreur / gardien. N'est pas appelé en continu.
- **C2 — `vf-new-lab`** : bootstrap de lab **universel** (non-dev en première classe). Cadrage 5
  questions (ce que l'utilisateur sait déjà) → dérivation → scaffolding adapté au métier. Exemple
  « acquisition » de bout en bout. Ne présume jamais dev.
- **C3 — `vf-calibrate`** + `scripts/framework-version.sh` : propagation d'update façon GSD.
  Détection de drift framework ↔ lab (current/recorded/stamp/drift, sémver portable), migration sous
  validation humaine, surfaçage SessionStart **opt-in**. + tests (8/8 PASS).
- **C4 — `references/contracts.md`** : protocole d'escalade sous-agents → conductor (gardien central).
- Références on-demand : `conductor-pipeline.md`, `migration-playbook.md`, `bootstrap-method.md`.

### Notes
- `type: agent + skills + scripts + references`. `requires: [planning-core, validator]`.
- Respecte ADR-031 (détecter/proposer, jamais corriger/migrer sans validation humaine), ADR-029
  (densité), ADR-030 (skills natifs, déléguer sans réimplémenter).
- Ne fait JAMAIS le travail métier — il configure et garde le lab.
