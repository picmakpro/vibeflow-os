# Codebase Structure

**Analysis Date:** 2026-07-26

## Directory Layout

```
vibeflow-os/                          # racine = marketplace (v2.36.1)
├── VERSION                           # canon de version racine (vX.Y.Z)
├── CHANGELOG.md                      # historique des releases racine
├── CLAUDE.md                         # règles repo (discipline release, densité, agents natifs)
├── README.md / README.fr.md          # vitrines EN/FR (badges version + compteur modules, gatés)
├── INSTALL.md · LICENSE · .gitattributes · .gitignore
├── .claude-plugin/
│   └── marketplace.json              # fiche marketplace → plugins[0].source: "./plugin"
├── .github/workflows/
│   └── ci.yml                        # 3 jobs : suites de tests · gates stricts · lab frais Gate C
├── scripts/                          # outillage RELEASE du repo (non distribué)
│   ├── bump.sh                       # bump synchronisé de toutes les sources de version
│   ├── check-version-sync.sh         # gate cohérence VERSION ↔ manifests ↔ badges ↔ triades
│   ├── check-release-tag.sh          # gate « toute version = un tag » (--remote)
│   └── hooks/pre-push                # câblage opt-in : git config core.hooksPath scripts/hooks
├── docs/                             # docs internes de dev — NON distribuées
│   ├── ADR.md                        # décisions d'architecture (fichier courant : ADR-046 → ADR-057)
│   ├── reference/                    # exigences/roadmaps historiques (install-ux, vfdo) + note spike
│   └── superpowers/
│       ├── specs/                    # designs datés YYYY-MM-DD-*.md (brainstorm → design)
│       └── plans/                    # plans d'implémentation datés
├── .planning/                        # état GSD du repo — NON distribué
│   ├── PROJECT.md · REQUIREMENTS.md · ROADMAP.md · STATE.md · MILESTONES.md · BACKLOG.md
│   ├── config.json
│   ├── codebase/                     # les 7 documents de cartographie (ce fichier)
│   ├── phases/                       # 01-dev-orchestrator … 14-frontiere-altitude-planning-gsd
│   ├── milestones/ · missions/ · research/
├── reports/                          # sorties d'audits horodatées (audit/, uat/, validator/)
└── plugin/                           # ★ LE BUNDLE DISTRIBUÉ (tout ce qui part chez l'utilisateur)
    ├── .claude-plugin/plugin.json    # manifest plugin (version, skills: ./installer)
    ├── installer/                    # skill /vibeflow-install (UX à toggles)
    │   ├── SKILL.md
    │   ├── scripts/{preflight.sh, build-module-catalog.sh, test-build-module-catalog.sh}
    │   └── tests/
    ├── _internal/                    # infrastructure d'install (pas un module)
    │   ├── vibeflow-update.sh        # engine scope-aware (install/update/uninstall/rollback/status)
    │   ├── resolve-deps.sh           # fermeture transitive des requires
    │   ├── merge-hooks.sh            # câbleur des hooks.json de modules (ADR-043)
    │   ├── retired-modules.txt       # manifeste des artefacts à nettoyer (convergence)
    │   └── tests/
    ├── commands/                     # slash-commands de gouvernance (pas de verbes dev)
    │   ├── vibeflow.md · vf-update.md · vf-audit.md
    │   └── vf-planning.md · vf-calibrate.md · vf-new-lab.md
    └── <module>/  × 17               # voir « Triade module » ci-dessous
```

## Les 17 modules sous `plugin/`

```
plugin/
├── conductor/                # MANDATORY — AGENT.md + skills/{vf-new-lab,vf-update,vf-calibrate}
│   ├── scripts/              # team-kernel (dag.sh, driver-lock.sh) + gates (check-agents.sh,
│   │                         #   guard-agent-write.sh, check-debug-research.sh, check-legacy.sh,
│   │                         #   check-overlaps.sh, check-plugin-update.sh, update-banner.sh,
│   │                         #   framework-version.sh, generate-agent-commands.sh, scaffold-docs.sh,
│   │                         #   vf-update-run.sh)
│   ├── references/           # team-kernel.md, bootstrap-method.md, conductor-pipeline.md,
│   │                         #   contracts.md, migration-playbook.md
│   ├── hooks/hooks.json · tests/
├── planning-core/            # SKILL.md + scripts/ (check-planning-state, planning-context,
│   │                         #   detect-planning-debt, guard-planning-updated, detect-gsd-engine…)
│   ├── references/           # GUIDE.md, PROFILES.md, compartments.md, gsd-handoff.md,
│   │                         #   bridge-memory.md, domain-detection.md, templates/
│   └── hooks/hooks.json
├── consolidator/             # SKILL.md + scripts/ (guards registres, reindex, archive, decay-pass…)
│   ├── references/           # indexation.md, archivage.md, fusion.md, promotion.md,
│   │                         #   memoire-vivante.md, templates-memoire/
│   └── hooks/hooks.json
├── validator/                # agent-only : AGENT.md (5 audits), incarné par /vf-audit
├── skill-creator/            # skills/{skill-creator, skill-creator-workflow}
├── audit-architecture/       # SKILL.md + references/
├── infrastructure-audit/     # SKILL.md + scripts/{audit-infra.sh, known-versions.txt} + hooks/
├── software-architecture/    # SKILL.md + rules/ + scripts/{check,guard}-file-size.sh + hooks/
├── reference/                # doc-only : content/methodology/ (VIBEFLOW_CORE.md v4.2,
│   │                         #   VIBEFLOW_EXPLAINED.md, VIBEFLOW_PHILOSOPHY.md,
│   │                         #   AXIOMES-ENFORCEMENT.md, patterns/01..12-*.md,
│   │                         #   templates/{agents,…}, vocabulary/)
│   └── content/examples/PetitsCoursFlow/
├── dev-orchestrator/         # AGENT.md (vibeflow-dev) + agents/{vf-dev-manager, vf-coder,
│   │                         #   vf-reviewer, vf-auditer} + skills/{vf-auto, vf-dev}
│   ├── references/           # intent-routing.md (carte d'intention UNIQUE), mission-flow.md,
│   │                         #   mission-contracts.md, gsd-skills-index.md, GSD-PIPELINE.md,
│   │                         #   autonomous-guardrails.md
│   └── scripts/              # ensure-deps.sh, build-gsd-index.sh, inject-mcp-tools.sh + tests
├── design-orchestrator/      # AGENT.md (vibeflow-design) + agents/{vf-design-manager, vf-crafter,
│   │                         #   vf-design-judge} + skills/{vf-design, vf-sketch} + references/
├── kpi-analyst/              # AGENT.md + scripts/{kpis-writer.sh, extractor-template.sh} + references/
├── mobile-test/              # SKILL.md + scripts/mobile-test-run.mjs + config/ + references/
├── mobile-test-team/         # agents/ (vf-test-orchestrator, vf-test-runner, vf-app-fixer) + rules/
├── content-bundle/           # agents/ + skills/vf-content + scripts/ + content/{agents,domain}
├── growth-bundle/            # même topologie que content-bundle
└── business-pilot-bundle/    # même topologie que content-bundle
```

## Directory Purposes

**`plugin/` (le distribuable):**
- Purpose: tout ce qui est copié dans le cache plugin puis installé dans les labs
- Contains: 17 modules + installer + _internal + commands + manifest
- Key files: `plugin/.claude-plugin/plugin.json`, `plugin/_internal/vibeflow-update.sh`

**`plugin/<module>/` — Triade module (invariant):**
- `VERSION` — version du module (vX.Y.Z, indépendante de la racine)
- `module.json` — contrat : name, version, type, description, `requires[]`, flags `mandatory`/`proposable`
- `CHANGELOG.md` — historique du module
- `README.md` — vitrine du module
- Puis selon le `type` : `AGENT.md` (agent principal), `agents/` (équipe), `SKILL.md` ou `skills/<nom>/SKILL.md`, `scripts/` (+ `scripts/tests/` ou `tests/`), `references/`, `rules/`, `hooks/hooks.json`, `config/`, `content/` (blueprints des bundles)

**`scripts/` (racine):**
- Purpose: outillage de release du REPO uniquement — jamais distribué
- Key files: `scripts/bump.sh`, `scripts/check-version-sync.sh`, `scripts/check-release-tag.sh`, `scripts/hooks/pre-push`

**`docs/`:**
- Purpose: mémoire de conception non distribuée
- Key files: `docs/ADR.md` (décisions numérotées), `docs/superpowers/specs/` (designs datés), `docs/superpowers/plans/` (plans datés), `docs/reference/` (requirements/roadmaps historiques)

**`.planning/`:**
- Purpose: état GSD du repo (PROJECT/ROADMAP/STATE/phases 01→14) + `codebase/` (cette cartographie)
- Generated: partiellement (par les skills gsd-*)
- Committed: oui

**`reports/`:**
- Purpose: sorties d'audits horodatées `YYYY-MM-DD-*.md`
- Contains: `reports/audit/`, `reports/uat/`, `reports/validator/`
- Committed: oui

**`.claude/` (racine repo):**
- Purpose: état local Claude Code du repo lui-même (agent-memory, logs, memory) — ne pas confondre avec le `.claude/` d'un lab cible
- Committed: non (majoritairement ignoré)

## Key File Locations

**Entry Points:**
- `plugin/installer/SKILL.md`: skill `/vibeflow-install` (première install, toggles, scope)
- `plugin/commands/vibeflow.md`: `/vibeflow` → agent `vibeflow-conductor`
- `plugin/dev-orchestrator/AGENT.md`: agent `vibeflow-dev` (routage NL dev)

**Configuration:**
- `VERSION` + `plugin/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`: les 3 sources de version (synchro gatée)
- `plugin/<module>/module.json`: contrat de chaque module

**Core Logic:**
- `plugin/_internal/vibeflow-update.sh`: engine d'install scope-aware
- `plugin/conductor/scripts/dag.sh` + `driver-lock.sh`: team-kernel
- `plugin/conductor/scripts/check-agents.sh`: lint agents natifs (ADR-044)
- `plugin/dev-orchestrator/references/intent-routing.md`: carte d'intention unique

**Testing:**
- `plugin/<module>/scripts/tests/` ou `plugin/<module>/tests/`: suites bash découvertes par la CI (`.github/workflows/ci.yml`, découverte non vide)
- Gros harness : `plugin/dev-orchestrator/scripts/test-dev-orchestrator.sh`

## Naming Conventions

**Files:**
- Scripts : `kebab-case.sh`, préfixes sémantiques — `check-*` (lint/gate), `guard-*` (hook bloquant), `detect-*`, `build-*`, `test-*` (suites)
- Agents d'équipe : `vf-<rôle>.md` dans `agents/` ; agent principal du module : `AGENT.md`
- Skills : `SKILL.md` (unique) ou `skills/<vf-nom>/SKILL.md`
- Specs/plans/rapports : datés `YYYY-MM-DD-<sujet>.md`
- Docs de référence module : `references/<sujet>.md` (minuscules), docs canoniques doctrine en `SCREAMING_SNAKE.md` (`VIBEFLOW_CORE.md`)

**Directories:**
- Modules : `kebab-case` (`dev-orchestrator`, `business-pilot-bundle`)
- Phases planning : `NN-sujet-kebab` (`.planning/phases/12-routage-fin-verbes/`)
- Préfixe `_` = interne non-module (`plugin/_internal/`)

## Where to Add New Code

**Nouveau module:**
- Créer `plugin/<nom>/` avec la triade `VERSION` + `module.json` (avec `requires[]`) + `CHANGELOG.md` + `README.md`
- Le compteur de modules des 2 README est gaté par `scripts/check-version-sync.sh` → mettre à jour badges + texte
- Release = **minor** de la racine (`scripts/bump.sh`)

**Nouvel agent (dans un module existant):**
- `plugin/<module>/agents/vf-<rôle>.md` — frontmatter natif complet (name, description, model, memory) sinon `check-agents.sh --strict` échoue en CI
- Worker interne dispatché par un manager : ajouter `vf-internal: true` (pas de commande d'incarnation)
- Respecter la densité ADR-029 (≤ 250 lignes)

**Nouveau script de module:**
- `plugin/<module>/scripts/<verbe-sujet>.sh` + suite `plugin/<module>/scripts/tests/` (la CI découvre les suites — une suite vide fait échouer la découverte)
- S'il doit tourner en hook dans le lab : le déclarer dans `plugin/<module>/hooks/hooks.json` avec le placeholder `{{VF_SCRIPTS}}`

**Nouvelle intention dev:**
- Éditer `plugin/dev-orchestrator/references/intent-routing.md` — JAMAIS créer une commande façade `/vf-*`

**Doctrine / pattern:**
- `plugin/reference/content/methodology/patterns/NN-<sujet>.md` ; décision structurante → nouvelle entrée `docs/ADR.md`

**Design avant implémentation:**
- Spec datée dans `docs/superpowers/specs/`, plan dans `docs/superpowers/plans/`

**Retrait d'un module:**
- Ajouter ses artefacts à `plugin/_internal/retired-modules.txt` (format `module:artefact`) pour la convergence à l'update

## Special Directories

**`plugin/<bundle>/content/`:**
- Purpose: blueprints d'origine des équipes bundle, trace de conception lisible par `vf-new-lab`
- Generated: non — Committed: oui

**`.planning/codebase/`:**
- Purpose: les 7 documents de cartographie (STACK, INTEGRATIONS, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, CONCERNS)
- Generated: oui (mappers GSD) — Committed: oui

**`.vibeflow-cache/`:**
- Purpose: cache d'install legacy/debug (défaut `VIBEFLOW_CACHE` de l'engine hors plugin)
- Generated: oui — Committed: non (`.gitignore`)

---

*Structure analysis: 2026-07-26*
