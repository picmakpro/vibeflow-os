# Codebase Structure

**Analysis Date:** 2026-10-02

## Directory Layout

```
vibeflow-os/                          # racine = marketplace (v2.67.1, tag v2.67.1)
├── VERSION                           # canon de version racine (vX.Y.Z)
├── CHANGELOG.md                      # historique des releases racine (section « Non releasé » sans crochets)
├── CLAUDE.md                         # règles repo (release = tag, quand publier, gardes in-repo, protection serveur)
├── README.md / README.fr.md          # vitrines EN/FR (badges version + compteur modules, gatés)
├── INSTALL.md · LICENSE · CONTRIBUTING.md · CODE_OF_CONDUCT.md · SECURITY.md
├── .gitattributes · .gitignore · .worktreeinclude
├── .claude-plugin/
│   └── marketplace.json              # fiche marketplace → plugins[0].source: "./plugin"
├── .github/                          # protection + CI du dépôt (revue code owner exigée)
│   ├── CODEOWNERS                    # périmètre étroit : .github/, baseline budget, .planning/.*-armed, scripts/hooks/
│   ├── rulesets/{main.json, tags-v.json}   # source versionnée des rulesets serveur
│   ├── workflows/{ci.yml, traffic-snapshot.yml}
│   ├── ISSUE_TEMPLATE/{bug_report.yml, feature_request.yml, config.yml}
│   └── PULL_REQUEST_TEMPLATE.md
├── scripts/                          # outillage RELEASE + PROTECTION du repo (non distribué)
│   ├── bump.sh                       # bump synchronisé de toutes les sources de version
│   ├── check-version-sync.sh         # gate cohérence VERSION ↔ manifests ↔ badges ↔ triades
│   ├── check-release-tag.sh          # gate « toute version = un tag » (--remote)
│   ├── check-machine-paths.sh        # aucun chemin absolu de machine dans les fichiers versionnés
│   ├── check-baseline-arbitrage.sh   # G-1 : hausse de baseline sans arbitrage cité
│   ├── check-gate-touche.sh          # G-2 : trailer Gate-Touche quand un gate/hook/CI change
│   ├── check-push-sans-pr.sh         # G-3 : alarme après coup, commit sur main sans PR
│   ├── check-affirmation-non-mesuree.sh   # G-4 : pas d'affirmation de protection serveur non mesurée
│   ├── measure-server-rulesets.sh    # compagnon de G-4 : mesure les rulesets via gh api
│   ├── check-gsd-core-update.sh      # sonde de veille @opengsd/gsd-core (désarmée)
│   ├── traffic-snapshot.sh           # snapshot hebdo des stats GitHub traffic
│   ├── hooks/{pre-push, post-merge}  # câblage opt-in : git config core.hooksPath scripts/hooks
│   └── tests/                        # 11 suites test-*.sh (+ fixtures/), dont test-role-hook-vs-check-agents.sh
├── docs/                             # docs internes de dev — NON distribuées
│   ├── ADR.md                        # décisions d'architecture (ADR-046 → ADR-075)
│   ├── HOOKS-CONTRAT-SORTIE.md       # contrat de sortie des hooks + inventaire des 31 entrées
│   ├── WINDOWS-HOOKS-PATHCONV.md     # portabilité des hooks Windows
│   ├── research/                     # notes de recherche
│   └── superpowers/
│       ├── specs/                    # 15 designs datés YYYY-MM-DD-*.md (dont moteur-planning-metier, fabrique-agents-skills)
│       └── plans/                    # plans d'implémentation datés
├── manual/                           # manuel utilisateur bilingue
│   ├── README.md · toc.yml
│   ├── en/{01-get-started … 07-under-the-hood}
│   └── fr/{01-demarrer … 07-sous-le-capot}
├── .planning/                        # état GSD du repo — NON distribué (voir « Planning du repo »)
│   ├── PROJECT.md · MILESTONES.md · BACKLOG.md · WINDOWS.md · config.json
│   ├── active-workstream             # compartiment par défaut (fiabilite)
│   ├── instruction-budget-baselines.tsv   # baseline du ratchet d'instructions (G-1)
│   ├── .instruction-budget-armed · .requirements-survival-armed   # sentinelles d'armement (CODEOWNERS)
│   ├── server-rulesets-measurement.json   # mesure G-4
│   ├── MISSION-*.dag.json · MISSION-INVARIANTS.md · DRIVER.lock* (gitignoré)
│   ├── workstreams/{fiabilite, gouvernance}/   # chacun : ROADMAP.md REQUIREMENTS.md STATE.md phases/ (+ quick/ pour gouvernance)
│   ├── codebase/                     # les 7 documents de cartographie (ce fichier)
│   ├── milestones/ · missions/ · quick/ · research/ · seeds/ · intel/ · notes/ · upstream/
├── reports/                          # sorties d'audits horodatées (audit/, uat/, validator/)
├── .claude/                          # état local Claude Code du repo (agent-memory versionné, reste ignoré)
├── .gsd/                             # état runtime du moteur GSD (ignoré)
└── plugin/                           # ★ LE BUNDLE DISTRIBUÉ (tout ce qui part chez l'utilisateur)
    ├── .claude-plugin/plugin.json    # manifest plugin (version, skills: ./installer)
    ├── installer/                    # skill /vibeflow-install
    │   ├── SKILL.md
    │   └── scripts/{preflight.sh, build-module-catalog.sh, tests/test-build-module-catalog.sh}
    ├── _internal/                    # infrastructure d'install (pas un module)
    │   ├── vibeflow-update.sh        # engine scope-aware (install/update/uninstall/rollback/status, --dry-run)
    │   ├── resolve-deps.sh · resolve-preset.sh · presets.json
    │   ├── merge-hooks.sh            # câbleur des hooks.json de modules (ADR-043)
    │   ├── runtime-cli-dispatch.sh   # dispatch multi-runtime
    │   ├── runtime-adapter/          # agent-to-codex.mjs, register-codex-agent.sh, tests/
    │   ├── lib/vf-portable.sh        # helpers de portabilité
    │   ├── retired-modules.txt       # manifeste des artefacts à nettoyer (convergence)
    │   └── tests/                    # 10 suites (+ fixtures/), dont test-planning-hook-installed.sh (canary CI)
    ├── commands/                     # 7 slash-commands de gouvernance (pas de verbes dev)
    │   ├── vibeflow.md · vf-update.md · vf-audit.md · vf-planning.md
    │   └── vf-calibrate.md · vf-new-lab.md · vf-notify.md
    └── <module>/  × 17               # voir « Les 17 modules sous plugin/ »
```

## Les 17 modules sous `plugin/`

```
plugin/
├── conductor/                # MANDATORY (v1.45.1) — AGENT.md + skills/{vf-new-lab,vf-update,vf-calibrate,vf-notify}
│   ├── scripts/              # team-kernel (dag.sh, driver-lock.sh, guard-driver-lock.sh, notify.sh) + gates
│   │                         #   (check-agents.sh, check-skills.sh, check-instruction-budget.sh,
│   │                         #   check-state-integrity.sh, check-divergence.sh, check-branch-claim.sh,
│   │                         #   check-workstream-pointer.sh, check-planning-consumers-registered.sh,
│   │                         #   check-guard-health.sh, check-method-budget.sh, check-map-drift.sh,
│   │                         #   check-mission-invariants.sh, check-blueprints.sh, check-legacy.sh,
│   │                         #   check-overlaps.sh, check-debug-research.sh, check-artifact-fidelity.sh,
│   │                         #   check-description-fidelity.sh, guard-agent-write.sh, …) + runtime-registry.sh,
│   │                         #   verify-runtime-reversibility.sh, generate-agent-commands.sh, scaffold-docs.sh,
│   │                         #   update-banner.sh, framework-version.sh, vf-update-run.sh, tests/ (33 suites)
│   ├── references/           # team-kernel.md, bootstrap-method.md, conductor-pipeline.md, contracts.md,
│   │                         #   migration-playbook.md, workstream-planning-consumers.md
│   └── hooks/hooks.json
├── consolidator/             # MANDATORY (v1.10.0) — SKILL.md + scripts/ (guards registres, reindex, archive,
│   │                         #   decay-pass, seed-registres, check-registres, probe-memory-guards… + tests/ 7 suites)
│   ├── references/           # indexation.md, archivage.md, fusion.md, promotion.md, memoire-vivante.md, templates-memoire/
│   └── hooks/hooks.json
├── planning-core/            # v2.9.0 — SKILL.md + hooks/hooks.json + references/ + scripts/
│   ├── hooks/hooks.json      # SessionStart ×5, UserPromptSubmit, Stop (guard-planning-updated), PreToolUse (hook central fail-closed)
│   ├── references/           # GUIDE.md, PROFILES.md, compartments.md, gsd-handoff.md, bridge-memory.md,
│   │   │                     #   domain-detection.md, example-lab-contenu.md,
│   │   │                     #   modele-cycles.md (contrat normatif cycles-v1 + hook central, ~1 040 L)
│   │   └── templates/        # gabarits socle v2 (*.template.md) + cycles/ (CYCLE, CADRAGE, PLAN, CLOTURE,
│   │                         #   VERDICT, SUMMARY, DEROGATION, config.template.json)
│   └── scripts/
│       ├── planning-hook.sh          # HOOK CENTRAL (lanceur bash + cœur Python heredoc) — table d'armement
│       ├── check-gates-alive.sh      # canary de session
│       ├── poser-verdict.sh · deroger-gate.sh   # seuls chemins vers VERDICT.md / dérogations
│       ├── rejeu-gates.sh · rejeu-reel.sh       # rejeu en lecture seule / geste sur lab réel
│       ├── recalc-planning.sh        # dérivation d'état par cycles (INDEX/STATE/cloture.log)
│       ├── detect-gsd-engine.sh · workstream-policy.sh · detect-planning-debt.sh · check-planning-state.sh
│       ├── guard-planning-updated.sh · planning-context.sh · planning-session-snapshot.sh · planning-task-context.sh
│       └── tests/                    # 12 suites + fixtures/{gates-banc.txt, recalc-planning-banc.txt}
├── validator/                # agent-only : AGENT.md (5 audits), incarné par /vf-audit
├── skill-creator/            # AGENT.md + skills/{skill-creator, skill-creator-workflow}
├── audit-architecture/       # SKILL.md + references/
├── infrastructure-audit/     # SKILL.md + scripts/{audit-infra.sh, known-versions.txt} + hooks/
├── software-architecture/    # SKILL.md + rules/ + scripts/{check,guard}-file-size.sh + hooks/
├── reference/                # doc-only : content/methodology/ (VIBEFLOW_CORE.md, VIBEFLOW_EXPLAINED.md,
│   │                         #   VIBEFLOW_PHILOSOPHY.md, AXIOMES-ENFORCEMENT.md, patterns/01..12-*.md,
│   │                         #   templates/{agents,…}, vocabulary/) + content/examples/
├── dev-orchestrator/         # AGENT.md (vibeflow-head) + agents/{vf-dev-manager, vf-coder, vf-reviewer,
│   │                         #   vf-auditer} + skills/{vf-auto, vf-dev} + hooks/hooks.json
│   ├── references/           # intent-routing.md (carte d'intention UNIQUE), head-governance.md, mission-flow.md,
│   │                         #   mission-contracts.md, mission-cross-team.md, workstreams.md, docs-flow.md,
│   │                         #   ingestion-flow.md, gsd-skills-index.md, gsd-capabilities-index.md,
│   │                         #   GSD-PIPELINE.md, autonomous-guardrails.md, _index.md
│   └── scripts/              # ensure-deps.sh, build-gsd-index.sh, build-gsd-capabilities-index.sh,
│                             #   inject-mcp-tools.sh, check-gsd-engine.sh, check-gsd-config.sh,
│                             #   check-requirements-survival.sh, requirements-survival-detect.sh,
│                             #   restore-requirements-ledger.sh, check-capability-activation.sh,
│                             #   check-dev-bootstrap.sh, check-doc-drift.sh, check-hook-paths.sh,
│                             #   check-mission-exit.sh, discover-unintegrated-docs.sh + tests/ (13 suites)
├── design-orchestrator/      # AGENT.md (vibeflow-design) + agents/{vf-design-manager, vf-crafter,
│   │                         #   vf-design-judge} + skills/{vf-design, vf-sketch} + references/ + scripts/
├── kpi-analyst/              # AGENT.md + SKILL.md + scripts/{kpis-writer.sh, extractor-template.sh} + references/
├── mobile-test/              # SKILL.md + scripts/mobile-test-run.mjs + config/ + references/
├── mobile-test-team/         # agents/ (vf-test-orchestrator, vf-test-runner, vf-app-fixer) + rules/
├── content-bundle/           # agents/ + skills/vf-content + scripts/ + content/{BUNDLE.md,agents,domain,registres.md}
├── growth-bundle/            # même topologie que content-bundle
└── business-pilot-bundle/    # même topologie que content-bundle
```

Décompte : **17 modules**, **25 définitions d'agents d'équipe** (`plugin/*/agents/*.md`) + **6
`AGENT.md`**, **83 scripts `.sh`** hors tests sous `plugin/*/scripts/`, **98 suites**
`test-*.sh` (87 sous `plugin/` : conductor 33, dev-orchestrator 13, planning-core 12,
`_internal` 12 dont 2 `runtime-adapter`, consolidator 7, autres modules 10 ; 11 sous
`scripts/tests/`).

## Directory Purposes

**`plugin/` (le distribuable):**
- Purpose: tout ce qui est copié dans le cache plugin puis installé dans les labs
- Contains: 17 modules + installer + `_internal` + commands + manifest
- Key files: `plugin/.claude-plugin/plugin.json`, `plugin/_internal/vibeflow-update.sh`

**`plugin/<module>/` — Triade module (invariant):**
- `VERSION` — version du module (vX.Y.Z, indépendante de la racine)
- `module.json` — contrat : name, version, type, description, `requires[]`, flags `mandatory`/`proposable`
- `CHANGELOG.md` — historique du module
- `README.md` — vitrine du module
- Puis selon le `type` : `AGENT.md`, `agents/`, `SKILL.md` ou `skills/<nom>/SKILL.md`, `scripts/` (+ `scripts/tests/`), `references/`, `rules/`, `hooks/hooks.json`, `config/`, `content/`

**`scripts/` (racine):**
- Purpose: outillage de release et de protection du REPO uniquement — jamais distribué
- Key files: `scripts/bump.sh`, `scripts/check-version-sync.sh`, `scripts/check-release-tag.sh`, `scripts/check-baseline-arbitrage.sh`, `scripts/check-gate-touche.sh`, `scripts/check-push-sans-pr.sh`, `scripts/hooks/pre-push`

**`.github/`:**
- Purpose: CI (4 jobs `tests` · `gates` · `lab-frais` · `lab-frais-arme`), rulesets versionnés, CODEOWNERS, gabarits d'issues/PR
- Revue `@picmakpro` exigée sur ce dossier : un changement de gate ou de CI porte un trailer `Gate-Touche:` (G-2)

**`docs/`:**
- Purpose: mémoire de conception non distribuée
- Key files: `docs/ADR.md`, `docs/HOOKS-CONTRAT-SORTIE.md`, `docs/superpowers/specs/` (designs datés), `docs/superpowers/plans/`

**`manual/`:**
- Purpose: manuel utilisateur bilingue, 7 sections numérotées par langue (`manual/en/`, `manual/fr/`), index `manual/toc.yml`

**`.planning/` (planning du repo):**
- Purpose: état GSD du repo, partitionné en compartiments sous `.planning/workstreams/`
- `fiabilite/` : compartiment par défaut (jalon `fiabilite-v1.0`, phases `VFDO-18` … `VFDO-41.1`, 15 dossiers)
- `gouvernance/` : jalon `gouvernance-labs-v1.0` (Phases 42-50 ; `VFDO-42` à `VFDO-45` présents) + `quick/` (19 entrées : corrections ciblées de la Phase 45)
- `.planning/quick/` (racine, 12 entrées) et `.planning/milestones/` : jalons clos et tâches rapides historiques
- Une commande GSD sans `--ws` résout `fiabilite` ; pour gouvernance : `--ws gouvernance`
- Generated: partiellement (par les skills gsd-*) — Committed: oui (sauf `DRIVER.lock*`, `state.json`, `.verification-ledger.json`)

**`reports/`:** sorties d'audits horodatées `YYYY-MM-DD-*.md` (`reports/audit/`, `reports/uat/`, `reports/validator/`) — Committed: oui

**`.claude/` (racine repo):** état local Claude Code du repo (`agent-memory/` versionné, hooks et scripts GSD installés ignorés) — ne pas confondre avec le `.claude/` d'un lab cible.

## Key File Locations

**Entry Points:**
- `plugin/installer/SKILL.md`: skill `/vibeflow-install`
- `plugin/commands/vibeflow.md`: `/vibeflow` → agent `vibeflow-conductor`
- `plugin/dev-orchestrator/AGENT.md`: agent `vibeflow-head`
- `plugin/planning-core/scripts/planning-hook.sh`: hook central PreToolUse (via la commande de `plugin/planning-core/hooks/hooks.json`)

**Configuration:**
- `VERSION` + `plugin/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`: les 3 sources de version (synchro gatée)
- `plugin/<module>/module.json`: contrat de chaque module
- `plugin/_internal/presets.json`: presets d'install (`dev`, `dev-mobile`, `dev-audite`)
- `.planning/config.json`, `.planning/active-workstream`: configuration GSD du repo

**Core Logic:**
- `plugin/_internal/vibeflow-update.sh`: engine d'install scope-aware
- `plugin/_internal/merge-hooks.sh`: câblage des hooks
- `plugin/conductor/scripts/dag.sh` + `driver-lock.sh`: team-kernel
- `plugin/conductor/scripts/check-agents.sh`: lint agents natifs (ADR-044)
- `plugin/dev-orchestrator/references/intent-routing.md`: carte d'intention unique
- `plugin/planning-core/scripts/recalc-planning.sh`: dérivation d'état par cycles
- `plugin/planning-core/scripts/planning-hook.sh`: table d'armement (`ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE`, `G2_MODE`)
- `plugin/planning-core/references/modele-cycles.md`: référence du modèle et du hook central (tenue égale au code par R-REFERENCE)

**Testing:**
- `plugin/<module>/scripts/tests/` ou `plugin/<module>/tests/` et `scripts/tests/`: suites `test-*.sh` découvertes par la CI (`find plugin scripts -type f -path '*/tests/test-*.sh'`, découverte non vide)
- Gates du hook central : `plugin/planning-core/scripts/tests/test-planning-gates.sh` (sémantique, mutants, R-REFERENCE), `test-planning-hook-registered.sh` (commande enregistrée), `test-rejeu-gates.sh` (rejeu) ; canary as-installed : `plugin/_internal/tests/test-planning-hook-installed.sh` ; rôle : `scripts/tests/test-role-hook-vs-check-agents.sh`
- Fixtures : `plugin/planning-core/scripts/tests/fixtures/{gates-banc.txt, recalc-planning-banc.txt}`
- Gros harness dev : `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`

## Naming Conventions

**Files:**
- Scripts : `kebab-case.sh`, préfixes sémantiques — `check-*` (lint/gate), `guard-*` (hook bloquant), `detect-*`, `build-*`, `rejeu-*`, `poser-*`, `deroger-*`, `test-*` (suites)
- Agents d'équipe : `vf-<rôle>.md` dans `agents/` ; agent principal du module : `AGENT.md`
- Skills : `SKILL.md` (unique) ou `skills/<vf-nom>/SKILL.md`
- Specs/plans/rapports : datés `YYYY-MM-DD-<sujet>.md`
- Docs de référence module : `references/<sujet>.md` (minuscules), doctrine canonique en `SCREAMING_SNAKE.md`
- Gabarits : `<NOM>.template.md` ; gabarits du modèle par cycles sous `references/templates/cycles/`

**Directories:**
- Modules : `kebab-case` (`dev-orchestrator`, `business-pilot-bundle`)
- Phases planning : `VFDO-NN-sujet-kebab` sous `.planning/workstreams/<compartiment>/phases/` ; artefacts `NN-MM-PLAN.md` / `NN-MM-SUMMARY.md`
- Tâches rapides : `YYMMDD-xxx-sujet` sous `quick/`
- Préfixe `_` = interne non-module (`plugin/_internal/`)
- Identifiants de décision préfixés par registre : `P45-D-05`, `PART-D-02` (jamais `D-05` nu)

## Where to Add New Code

**Nouveau module:**
- Créer `plugin/<nom>/` avec la triade `VERSION` + `module.json` (avec `requires[]`) + `CHANGELOG.md` + `README.md`
- Le compteur de modules des 2 README est gaté par `scripts/check-version-sync.sh` → mettre à jour badges + texte
- Release = **minor** de la racine (`scripts/bump.sh`) — seulement si évolution fonctionnelle (ADR-073)

**Nouvel agent (dans un module existant):**
- `plugin/<module>/agents/vf-<rôle>.md` — frontmatter natif complet (name, description, model, memory) sinon `check-agents.sh --strict` échoue en CI
- Worker interne dispatché par un manager : `vf-internal: true`
- Densité ADR-029 (bloque au-delà de 300 lignes, avertissement dès 251) ; baseline d'instructions : `.planning/instruction-budget-baselines.tsv` (toute hausse exige une citation d'arbitrage, G-1)

**Nouveau script de module:**
- `plugin/<module>/scripts/<verbe-sujet>.sh` + suite `plugin/<module>/scripts/tests/test-<verbe-sujet>.sh`
- Hook dans le lab : le déclarer dans `plugin/<module>/hooks/hooks.json` avec `{{VF_SCRIPTS}}` (forme shell) ou `{{VF_BASH}}` + `args` (forme exec, routée vers `settings.local.json`)
- Un script qui référence un chemin d'artefact de planning est recensé dans `plugin/conductor/references/workstream-planning-consumers.md`

**Nouveau gate d'écriture du moteur de planning (planning-core):**
- Constante `ARMEMENT_<GATE>` dans `plugin/planning-core/scripts/planning-hook.sh` (entrée de `TABLE_ARMEMENT`, `ORDRE_ETAPES`, `GATES_A_VERDICT`) ; démarrer en `observe`
- Cas de canary dans `plugin/planning-core/scripts/check-gates-alive.sh` (un gate armé sans cas est signalé)
- Constructeur de rejeu dans `plugin/planning-core/scripts/rejeu-gates.sh`, banc dans `plugin/planning-core/scripts/tests/fixtures/gates-banc.txt`
- Table et limites dans `plugin/planning-core/references/modele-cycles.md` + `TABLE_ATTENDUE` dans `plugin/planning-core/scripts/tests/test-planning-gates.sh` (R-REFERENCE rougit sur un écart)
- Armement : rejeu réel par `rejeu-reel.sh`, un commit par étape, trailer `Gate-Touche:`

**Nouvelle intention dev:**
- Éditer `plugin/dev-orchestrator/references/intent-routing.md` — JAMAIS une commande façade `/vf-*`

**Nouveau gate/script de protection du dépôt:**
- `scripts/check-<sujet>.sh` + `scripts/tests/test-check-<sujet>.sh` + une étape dans `.github/workflows/ci.yml` (job `gates`) ; marqueur `Gate-Touche:` dans le commit

**Doctrine / pattern:**
- `plugin/reference/content/methodology/patterns/NN-<sujet>.md` ; décision structurante → nouvelle entrée `docs/ADR.md`

**Design avant implémentation:**
- Spec datée dans `docs/superpowers/specs/`, plan dans `docs/superpowers/plans/`

**Planning d'une phase (jalon gouvernance):**
- `.planning/workstreams/gouvernance/phases/VFDO-NN-…/`, tâche rapide dans `.planning/workstreams/gouvernance/quick/` ; toujours `--ws gouvernance`

**Retrait d'un module:**
- Ajouter ses artefacts à `plugin/_internal/retired-modules.txt` (format `module:artefact`)

## Special Directories

**`plugin/<bundle>/content/`:**
- Purpose: blueprints d'origine des équipes bundle, trace de conception lisible par `vf-new-lab`
- Generated: non — Committed: oui

**`.planning/codebase/`:**
- Purpose: les 7 documents de cartographie (STACK, INTEGRATIONS, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, CONCERNS)
- Generated: oui (mappers GSD) — Committed: oui

**`.planning/.instruction-budget-armed`, `.planning/.requirements-survival-armed`:**
- Purpose: sentinelles d'armement des ratchets ; neutraliser l'une exige une citation d'arbitrage (G-1) et la revue code owner
- Generated: non — Committed: oui

**`.planning/DRIVER.lock*`, `.gsd/`, `.planning/state.json`:**
- Purpose: état runtime local (verrou de driver, sentinelle de dispatch-isolation, projection GSD)
- Generated: oui — Committed: non (`.gitignore`)

**`.claude/worktrees/`:**
- Purpose: worktrees d'agents isolés (une session = un worktree) ; `.worktreeinclude` liste les chemins ignorés recopiés
- Generated: oui — Committed: non

**`.vibeflow-cache/`:**
- Purpose: cache d'install legacy/debug (défaut `VIBEFLOW_CACHE` de l'engine hors plugin)
- Generated: oui — Committed: non (`.gitignore`)

---

*Structure analysis: 2026-10-02*
