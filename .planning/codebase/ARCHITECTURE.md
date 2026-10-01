<!-- refreshed: 2026-10-02 -->
# Architecture

**Analysis Date:** 2026-10-02

## System Overview

vibeflow-os est le **repo de distribution** du plugin Claude Code « VibeFlow » (racine `VERSION` =
v2.67.1, tag `v2.67.1` posé) : un marketplace (`.claude-plugin/marketplace.json`) qui expose un
plugin unique (`plugin/`) composé de **17 modules toggables** + une infrastructure d'install
(installer, engine scope-aware, résolveur de deps et de presets, câbleur de hooks, adaptateur
multi-runtime). Le repo lui-même n'exécute rien en production : il est packagé par Claude Code
dans un **cache** (`${CLAUDE_PLUGIN_ROOT}`), puis l'engine copie les artefacts des modules choisis
dans le `.claude/` d'un **lab** (scope user / project / local).

Ce repo n'est PAS un lab adhérent au moteur de planning par cycles : les hooks de `planning-core`
y sont silencieux (voir « Le moteur de planning par cycles »).

```text
┌──────────────────────────────────────────────────────────────────────┐
│  Repo vibeflow-os (marketplace)                                      │
│  `.claude-plugin/marketplace.json` → source: ./plugin                │
├──────────────────────────────────────────────────────────────────────┤
│  plugin/  (le bundle distribué, manifest `plugin/.claude-plugin/     │
│  plugin.json`, skills: ./installer, 7 commandes `plugin/commands/`)  │
│  ┌──────────────┬──────────────────┬───────────────────────────────┐ │
│  │ 17 modules   │ installer/       │ _internal/                    │ │
│  │ <module>/    │ SKILL.md         │ vibeflow-update.sh (engine)   │ │
│  │ VERSION +    │ preflight.sh     │ resolve-deps.sh · presets     │ │
│  │ module.json +│ build-module-    │ merge-hooks.sh (ADR-043)      │ │
│  │ CHANGELOG.md │ catalog.sh       │ runtime-adapter/ · lib/       │ │
│  └──────────────┴──────────────────┴───────────────────────────────┘ │
└───────────────────────────┬──────────────────────────────────────────┘
                            │  install du plugin par Claude Code
                            ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Cache local = ${CLAUDE_PLUGIN_ROOT} (modules + module.json à plat)  │
└───────────────────────────┬──────────────────────────────────────────┘
                            │  /vibeflow-install → engine scope-aware
                            │  VF_SCOPE ∈ user|project|local
                            ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Lab installé — TARGET_ROOT/.claude/                                 │
│  agents/  skills/  rules/  scripts/ (à plat)                         │
│  agents/<module>-references/                                         │
│  hooks mergés : settings.json (forme shell / exec-safe)              │
│                 settings.local.json (entrées {{VF_BASH}}, machine)   │
│  registre des modules installés + versions                           │
└──────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Marketplace | Fiche d'install vue par l'utilisateur (version, description) | `.claude-plugin/marketplace.json` |
| Plugin manifest | Identité du plugin, pointe le skill d'entrée sur `./installer` | `plugin/.claude-plugin/plugin.json` |
| Skill d'install | UX à toggles, orchestrateur thin qui DÉLÈGUE aux briques | `plugin/installer/SKILL.md` |
| Préflight (ADR-054) | Prérequis durs (git, jq, python3 exécutable — piège stub Windows) | `plugin/installer/scripts/preflight.sh` |
| Catalogue | Construit la liste des modules installables depuis le cache | `plugin/installer/scripts/build-module-catalog.sh` |
| Engine scope-aware | install / update / uninstall / rollback / status par module, `--dry-run`, source = cache (plus de git clone) | `plugin/_internal/vibeflow-update.sh` (~3 270 L) |
| Résolveur de deps | Fermeture transitive des `requires` des module.json | `plugin/_internal/resolve-deps.sh` |
| Presets d'install | `dev`, `dev-mobile`, `dev-audite` : listes de modules RACINES, fermeture calculée, jamais recopiée | `plugin/_internal/presets.json`, `plugin/_internal/resolve-preset.sh` |
| Câbleur de hooks (ADR-043) | Merge/remove/plan idempotent des `hooks/hooks.json` dans les settings du lab (`{{VF_SCRIPTS}}`, `{{VF_BASH}}`) | `plugin/_internal/merge-hooks.sh` |
| Portabilité | Helpers partagés (Windows/WSL, chemins) | `plugin/_internal/lib/vf-portable.sh` |
| Multi-runtime | Dispatch CLI + conversion d'agents vers Codex/OpenCode/kimi | `plugin/_internal/runtime-cli-dispatch.sh`, `plugin/_internal/runtime-adapter/` |
| Convergence des retraits | Nettoie les artefacts des modules retirés du parc | `plugin/_internal/retired-modules.txt` |
| Commandes plugin | Slash-commands de gouvernance (`/vibeflow`, `/vf-update`, `/vf-audit`, `/vf-planning`, `/vf-calibrate`, `/vf-new-lab`, `/vf-notify`) | `plugin/commands/*.md` |
| Gates repo | Discipline release + protection du dépôt, machine-enforced | `scripts/check-*.sh`, `scripts/bump.sh`, `scripts/hooks/` |
| Protection serveur (versionnée) | Rulesets `main` et tags `v*`, CODEOWNERS | `.github/rulesets/main.json`, `.github/rulesets/tags-v.json`, `.github/CODEOWNERS` |
| CI | 4 jobs : `tests`, `gates`, `lab-frais`, `lab-frais-arme` | `.github/workflows/ci.yml` |

## Les 17 modules (rôles et dépendances)

Chaque module = un dossier `plugin/<module>/` avec la triade `VERSION` + `module.json`
(name, version, type, description, `requires[]`, flags `mandatory` / `proposable`) +
`CHANGELOG.md` (+ `README.md`). Versions lues dans les `VERSION` au 2026-10-02.

| Module | Version | Type | Rôle | requires |
|---|---|---|---|---|
| **conductor** | v1.45.1 | agent + skills + scripts + references | **Mandatory.** Orchestrateur méta / gardien du lab (`AGENT.md`, `vibeflow-conductor`), skills `vf-new-lab` (Lab Factory), `vf-update`, `vf-calibrate`, `vf-notify`. **Hôte du team-kernel** et de la majorité des gates machine (`scripts/check-*.sh`) | planning-core, validator, skill-creator |
| **consolidator** | v1.10.0 | single-skill + scripts | **Mandatory.** Mémoire projet sur **5 piliers** (indexation, archivage, fusion, promotion, mémoire vivante ADR-052) + hooks de gouvernance mémoire ADR-032/043 | — |
| **planning-core** | v2.9.0 | skill + references + scripts | Socle `.planning/` universel + altitude lab (compartiments, index, dette) + **moteur de planning par cycles `cycles-v1`** (`recalc-planning.sh`) + **hook central PreToolUse par rôle et gates d'écriture** (`planning-hook.sh`). Frontière ADR-055 : ses hooks de fraîcheur se retirent (`--defer-to-gsd`) quand un moteur GSD tient le projet. **Non releasé** (pas de bump racine, ADR-073) | — |
| **validator** | v1.3.5 | agent-only | Agent garant de l'alignement lab ↔ méthodologie (5 audits), incarné par `/vf-audit` | consolidator, infrastructure-audit, audit-architecture |
| **skill-creator** | v1.1.1 | agent + skills | Pattern agent minimal + 2 skills composables (`skill-creator`, `skill-creator-workflow`) | — |
| **audit-architecture** | v1.0.3 | single-skill + references | Méta-skill concepteur d'architectures d'audit multi-couches (ADR-036) | — |
| **infrastructure-audit** | v1.3.2 | single-skill + scripts | Garde-fou technique : drift Anthropic, intégrité scripts (`scripts/audit-infra.sh`) | — |
| **software-architecture** | v1.6.1 | single-skill + rules + scripts | Doctrine AI-safe (SOLID, Clean Arch, gates Nyquist + Decision Coverage) + garde machine seuil 300 L (`scripts/guard-file-size.sh`) | — |
| **reference** | v2.5.6 | doc-only | Doctrine distribuée : Core (`content/methodology/VIBEFLOW_CORE.md`), **12 patterns** (`content/methodology/patterns/01..12-*.md`), templates d'agents, vocabulaire | — |
| **dev-orchestrator** | v2.25.0 | agent + skills + scripts | **Modèle agentique** : agent `vibeflow-head` (opus) route le langage naturel via la **carte d'intention unique** (`references/intent-routing.md`) vers les briques gsd-*/superpowers et **lance l'équipe** (`vf-coder`, `vf-dev-manager`). Skills `vf-auto`, `vf-dev`. Porte les gates GSD (`check-gsd-engine.sh`, `check-requirements-survival.sh`, `check-capability-activation.sh`…) | conductor, design-orchestrator |
| **design-orchestrator** | v1.5.11 | agent + skills | Agent routeur `vibeflow-design`, skills `vf-design` / `vf-sketch`, équipe design sur le team-kernel | conductor |
| **kpi-analyst** | v1.0.6 | agent + skill + scripts | KPIs métier déterministes → registre `KPIS.md` (jamais de chiffre inventé) | planning-core, consolidator |
| **mobile-test** | v1.0.2 | skill + script + config | Pipeline test mobile réel (Maestro, `scripts/mobile-test-run.mjs`) | — |
| **mobile-test-team** | v1.4.6 | agents + rules | Boucle autonome test → corrige → re-test (`vf-test-orchestrator` + `vf-test-runner` / `vf-app-fixer`, Pattern 12) | mobile-test |
| **content-bundle** | v2.0.13 | agents + skill + scripts | Équipe content sur le team-kernel (`vf-content-manager` + workers + juge `content-clarity-judge`). `proposable: true` | conductor, planning-core, consolidator, audit-architecture, validator |
| **growth-bundle** | v2.0.12 | agents + skill + scripts | Équipe growth (`vf-growth-manager` + workers + `growth-quality-judge`), envoi réel human-gated. `proposable: true` | idem content-bundle |
| **business-pilot-bundle** | v2.0.13 | agents + skill + scripts | Équipe business (`vf-business-manager`, workers commercial/delivery/finance + `quality-gate-client`). `proposable: true` | idem content-bundle |

**Graphe de dépendances (baseline)** : `conductor` (mandatory) tire `planning-core` +
`validator` + `skill-creator` ; `validator` tire `consolidator` + `infrastructure-audit` +
`audit-architecture`. Les 3 bundles métier et `dev-orchestrator` se posent par-dessus.
Résolution : `plugin/_internal/resolve-deps.sh` (`install --with-deps`) ; les presets de
`plugin/_internal/presets.json` ne portent que des modules proposables.

Inventaire d'agents : 25 définitions d'équipe sous `plugin/*/agents/*.md` + 6 agents principaux
`plugin/<module>/AGENT.md` (conductor, dev-orchestrator, design-orchestrator, validator,
kpi-analyst, skill-creator).

## Le moteur de planning par cycles (planning-core v2.9.0, Phase 44-45)

Second modèle de données de `planning-core`, **additif** au socle v2 (profils
léger/standard/complet, `plugin/planning-core/references/templates/*.template.*` inchangés).
Contrat normatif : `plugin/planning-core/references/modele-cycles.md` (§ Adhésion, § Arborescence,
§ Hook central et gates d'écriture). Un lab n'est concerné que si `.planning/config.json`
déclare `"planning_version": "cycles-v1"` (égalité stricte de chaîne). Un lab dev (GSD) n'est
**jamais** réécrit ni refusé ; ce dépôt non plus.

```text
 PreToolUse (Write|Edit|NotebookEdit|Bash|Agent|Task)        SessionStart (startup)
        │                                                            │
        ▼                                                            ▼
┌───────────────────────────────────────────────┐     ┌──────────────────────────────┐
│ commande ENREGISTRÉE (forme shell, timeout 20)│     │ canary de session            │
│ `plugin/planning-core/hooks/hooks.json`       │     │ `scripts/check-gates-alive.sh`│
│ lance planning-hook.sh en fils ; tout code    │     │ rejoue la commande de       │
│ non nul = REPRIS : fail-closed dans un lab    │     │ référence sur un lab        │
│ adhérent (sans python3), silence ailleurs     │     │ synthétique ; SIGNALE, ne   │
└───────────────────┬───────────────────────────┘     │ bloque jamais               │
                    ▼                                  └──────────────────────────────┘
┌───────────────────────────────────────────────┐
│ lanceur bash + cœur Python embarqué (heredoc) │   `plugin/planning-core/scripts/planning-hook.sh`
│ adhésion → armement_valide → G2 (avertit)     │
│ → G6, G5, G1, G7, ROLE (GATES_A_VERDICT)      │
│ → decider → `deny` JSON, code 0               │
└───────────────────┬───────────────────────────┘
                    ▼
   `.planning/derogations-gates.log` (dérogations, consommées)
   journal d'observation (cache utilisateur) pour un gate en `observe`
```

**Hook central** : UN script (`plugin/planning-core/scripts/planning-hook.sh`, ~2 000 L) porte
les gates d'écriture (G1, G2, G5, G6, G7) et le cloisonnement par rôle (ROLE, fabrique
d'agents). Le lanceur bash lit le payload JSON sur stdin vers un fichier `mktemp` (0600) et passe
le cœur Python embarqué en heredoc quoté sur stdin (`python3 -I -S -`) : aucun `.py` posé par
l'installeur. Codes du lanceur : `0` décidé, `3` erreur Python avant adhésion connue, `70`
mktemp, `71` stdin, `72` aucun interpréteur, `73` échéance interne du cœur (`ECHEANCE_COEUR_S` =
8 s). Le cœur ne lit **aucune** variable d'environnement : `TMPDIR`, `XDG_CACHE_HOME`, `HOME`
choisissent des chemins (passés en `sys.argv`), jamais une décision (P45-D-12a).

**Commande enregistrée fail-closed** (`plugin/planning-core/hooks/hooks.json`, entrée
`PreToolUse`) : commande de forme shell (posée dans `settings.json`, jamais en forme exec
`{{VF_BASH}}`). Si le script ou `python3` manque, plante ou dépasse l'échéance, elle décide
elle-même, sans `python3`, si le lab est adhérent (extraction shell du chemin, remontée au plus
proche `.planning`, motif `MOTIF_ADHESION_REPLI` sur `config.json`) : dans un lab adhérent ou
dans le doute elle refuse `Write`, `Edit`, `NotebookEdit`, `Agent`, `Task` (jamais `Bash`,
P45-D-06b) ; ailleurs elle se tait. Un refus est un JSON `permissionDecision: "deny"` en code 0,
jamais un `exit 2` (P45-D-08).

**Table d'armement** (constantes `ARMEMENT_*` du code livré, jamais un fichier du lab ni une
variable d'environnement — P45-D-03a). Armement en cascade, un commit par étape, état livré en
v2.9.0 :

| Gate | Étape | État | Rôle |
|---|---|---|---|
| G6 | 1 | **armé** | refuse l'écriture par outil des fichiers générés (`STATE.md`, `INDEX.md`, `cloture.log`, `.recalc-cache.json`, `derogations-gates.log`, adhésion de `config.json`) et des scripts du hook en scope projet (`planning-hook.sh`, `check-gates-alive.sh`) |
| G5 | 1 | **armé** | refuse l'écriture par outil de `VERDICT.md` (seul chemin : `poser-verdict.sh`) |
| G1 | 2 | **armé** | pas de `PLAN.md` sans `CADRAGE.md` dans la phase |
| G7 | 3 | **armé** | pas de `.planning/` orphelin créé sous un lab adhérent (sauf marqueur de code ou `.claude/` habité) |
| ROLE | 4 | **armé** | juge : aucune écriture par outil ; worker : dispatch `Agent`/`Task` limité à sa propre allowlist |
| G2 | - | **avertit** (`G2_MODE = "avertit"`) | `additionalContext` sur une écriture hors du `ecrit:` des plans ouverts ; ne refuse jamais |

Commandes compagnes (toutes dans `plugin/planning-core/scripts/`) :

| Commande | Rôle | Codes |
|---|---|---|
| `recalc-planning.sh` | dérive du disque l'état d'un planning `cycles-v1`, génère `INDEX.md`, `STATE.md`, `cloture.log`. **Levée du code 2 sous adhésion (GATE-14)** : un lab adhérent qui contient du code (détecteur GSD à 2, signalement de migration) est désormais écrit, le socle v2 (`STATE.md`/`INDEX.md` manuscrits) étant archivé sous `.planning/_archive/socle-v2/` ; sans adhésion le refus 2 est inchangé ; planning GSD détecté ou non concluant : 3 | 0 / 1 / 2 / 3 / 64 |
| `poser-verdict.sh` | SEUL chemin légitime vers `VERDICT.md` (hash sha256 du `PLAN.md` et tentative vérifiés par la commande) | 0 / 1 / 2 / 64 |
| `deroger-gate.sh` | dérogation nominative (qui, canal, date, gate, chemins, raison non placeholder), append-only, usage unique, citée par le hook | 0 / 1 / 2 / 64 |
| `check-gates-alive.sh` | canary de session (`--hook` sous `SessionStart`) : hook absent, commande non reconnue, mode dégradé, constantes d'armement absentes, gate armé sans cas, couverture incomplète | 0 signal / 3 sain / 4 indéterminé / 64 |
| `rejeu-gates.sh` | rejeu en lecture seule sur une COPIE du lab : faux refus, faux accept, refus conformes au modèle par gate | 0 / 1 / 64 |
| `rejeu-reel.sh` | geste de rejeu sur lab réel : empreinte de TOUT l'arbre avant/après, `MESURE-VIDE` si rien mesuré | 0 / 1 / 64 |

Autres scripts hérités du socle (altitude lab, inchangés) : `workstream-policy.sh`,
`detect-planning-debt.sh`, `detect-gsd-engine.sh`, `check-planning-state.sh`,
`planning-context.sh`, `planning-session-snapshot.sh`, `planning-task-context.sh`. Le Stop hook
`guard-planning-updated.sh` est **conservé** et reste en `exit 2` (P45-D-19).

**Preuve** : le contrôle croisé R-REFERENCE de `plugin/planning-core/scripts/tests/test-planning-gates.sh`
compare la table d'armement, les noms protégés par G6, les marqueurs de code de G7, l'ordre de
résolution des agents, les limites (a) à (ae) et la commande de `hooks.json` à la référence
`modele-cycles.md` ; `plugin/_internal/tests/test-planning-hook-installed.sh` installe le module
par l'installeur inchangé et rejoue la commande telle que posée ;
`scripts/tests/test-role-hook-vs-check-agents.sh` compare le rôle dérivé par le hook à
`plugin/conductor/scripts/check-agents.sh`.

## Le team-kernel (hébergé par conductor, ADR-053)

Socle d'orchestration d'équipe transverse à tous les métiers, hébergé par le module mandatory.
Doc : `plugin/conductor/references/team-kernel.md`.

| Brique | Implémentation | Garantie |
|---|---|---|
| Verrou de driver | `plugin/conductor/scripts/driver-lock.sh` (acquire / heartbeat / release, TTL + recovery, lien symbolique + dossiers de génération) | une seule mission pilote à la fois |
| Garde du verrou | `plugin/conductor/scripts/guard-driver-lock.sh` (PreToolUse Bash, Write\|Edit) | pas de commit/checkout/écriture `.planning/` sous lock d'autrui |
| Plan de bataille (DAG) | `plugin/conductor/scripts/dag.sh` (init / add --deps / ready / mark / reopen) | dispatch de la frontière `ready` en parallèle |
| Rapports typés (Pattern C) | `{ statut: passed\|gaps_found\|human_needed\|blocked, findings[], noeuds_debloques[] }` | fin du pilotage à la prose |
| Halt conditions (P11) | 5 codes — `plugin/reference/content/methodology/patterns/11-halt-conditions.md` | arbitrage humain en 30 s |
| Notifications | `plugin/conductor/scripts/notify.sh` (fail-open silencieux, opt-in), skill `vf-notify` | jalons de mission signalés |
| Cloisonnement par tools (P12) | juges sans Write/Edit, workers sans Task, `vf-internal: true` — linté par `check-agents.sh`, **appliqué à l'exécution dans un lab `cycles-v1` par le rôle de `planning-hook.sh`** | anti-triche machine-enforced |
| Revendication de branche | `plugin/conductor/scripts/check-branch-claim.sh` (ADR-064) | un écrivain = un worktree |

| Équipe | Module | Manager | Workers | Juges |
|---|---|---|---|---|
| Dev (référence) | dev-orchestrator | `agents/vf-dev-manager.md` | `vf-coder.md` | `vf-reviewer.md`, `vf-auditer.md` |
| Design | design-orchestrator | `agents/vf-design-manager.md` | `vf-crafter.md` | `vf-design-judge.md` |
| Mobile | mobile-test-team | `vf-test-orchestrator` | `vf-app-fixer`, `vf-test-runner` | (le test EST le juge) |
| Content / Growth / Business | 3 bundles | `vf-content-manager` / `vf-growth-manager` / `vf-business-manager` | workers cloisonnés par bundle | juges frais read-only |

## Le modèle agentique

- L'agent `vibeflow-head` (`plugin/dev-orchestrator/AGENT.md`, opus, memory: project) détecte
  l'intention en langage naturel, **gouverne et lance l'équipe** (`Task(vf-coder)` pour une tâche
  courte, `Task(vf-dev-manager)` / `Task(vf-design-manager)` au-delà) ; incarné en session
  principale (`/vf-dev`) ou en autonomie (`vf-auto`), jamais dispatché lui-même (profondeur 1
  réservée aux managers). Doctrine : `plugin/dev-orchestrator/references/head-governance.md`.
- **Aucune couche de synonymes / façade de verbes** `/vf-*` dev (supprimée en v2.33.0, spec
  `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`).
- **Source unique de routage** : `plugin/dev-orchestrator/references/intent-routing.md`.
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` installe les briques gsd-* manquantes ;
  `build-gsd-index.sh` / `build-gsd-capabilities-index.sh` génèrent les index ;
  `inject-mcp-tools.sh` dérive l'allowlist MCP des exécutants (ADR-051).
- **Agents natifs machine-enforced (ADR-044)** : tout agent posé passe
  `plugin/conductor/scripts/check-agents.sh` (name, **description**, **model**, **memory**,
  skills existants, champs inconnus rejetés). Worker interne : `vf-internal: true`.
- **Skills par nature** (Phase 43) : `plugin/conductor/scripts/check-skills.sh` exige
  `vf-nature: referentiel | outil | procedure` (défaut `outil`).

## Planning du repo : partitionné en workstreams (PR #94)

Le `.planning/` de CE repo (non distribué) est partitionné par compartiment :
`.planning/workstreams/fiabilite/` (compartiment par défaut, `.planning/active-workstream`) et
`.planning/workstreams/gouvernance/` (jalon `gouvernance-labs-v1.0`, Phases 42-50). Chaque
compartiment porte son `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `phases/`. Une commande GSD
qui ne précise rien résout `fiabilite` ; pour gouvernance : `--ws gouvernance`
(ou `GSD_WORKSTREAM`, `--ws` l'emporte). Les gates de planning sont rejoués à la main sur
`gouvernance` tant que la Phase 41.1 n'est pas mergée. Garde-fous : `workstream-policy.sh`,
`check-workstream-pointer.sh`, `check-divergence.sh`, `check-state-integrity.sh`.

## Data Flow

### Install (chemin principal)

1. L'utilisateur ajoute le marketplace → Claude Code copie `plugin/` dans le cache `${CLAUDE_PLUGIN_ROOT}` (`.claude-plugin/marketplace.json`)
2. `/vibeflow-install` (`plugin/installer/SKILL.md`) — UX à toggles, choix du scope ou d'un preset
3. `preflight.sh` → `build-module-catalog.sh` → `resolve-deps.sh` / `resolve-preset.sh`
4. `plugin/_internal/vibeflow-update.sh --scope <s> install --with-deps <module>` — copie les artefacts vers `TARGET_ROOT/.claude/` (user → `$HOME/.claude`, project/local → `./.claude`, local ajoute au `.gitignore`)
5. `merge-hooks.sh merge` câble les `hooks/hooks.json` dans les settings du lab : `{{VF_SCRIPTS}}` → chemin réel ; les entrées portant `{{VF_BASH}}` (chemin de bash machine-spécifique) vont dans `settings.local.json`, les formes shell dans `settings.json` (c'est là que `planning-core` pose sa commande fail-closed)

### Update

1. `update-banner.sh` (SessionStart, conductor) signale une nouvelle version → `/vf-update` (`plugin/commands/vf-update.md` → skill `plugin/conductor/skills/vf-update/`)
2. `vibeflow-update.sh update --all` depuis le cache + `cleanup_retired_modules` via `plugin/_internal/retired-modules.txt`
3. Rollback possible : `vibeflow-update.sh rollback <module>` (backups)

### Écriture dans un lab adhérent `cycles-v1`

1. Un agent appelle `Write`/`Edit`/`NotebookEdit`/`Bash`/`Agent`/`Task` → harnais → commande enregistrée (`plugin/planning-core/hooks/hooks.json`)
2. `planning-hook.sh` : racine du lab dérivée du chemin écrit → adhésion → G2 → gates à verdict → `deny` JSON ou silence
3. Un verdict légitime : le juge ou son manager lance `poser-verdict.sh` par `Bash` ; une exception : `deroger-gate.sh`, citée à la consommation
4. L'état dérivé se régénère par `recalc-planning.sh` (`STATE.md`, `INDEX.md`, `cloture.log`)

### Release du repo

1. `scripts/bump.sh` — même numéro dans `VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, badges des 2 README + squelette CHANGELOG
2. `scripts/check-version-sync.sh` — gate de cohérence
3. PR → 4 checks requis → merge sur `main` → tag annoté `vX.Y.Z` + release GitHub → `scripts/check-release-tag.sh --remote`
4. **Une release ne se déclenche que pour une évolution fonctionnelle** (ADR-073) : doc, specs, planning, et `planning-core` v2.9.0 (livré sans bump racine) partent avec la prochaine release fonctionnelle

**State Management:**
- Repo : `.planning/` (GSD, partitionné en workstreams) — non distribué.
- Lab : registre des modules installés + versions, tenu par l'engine (`vibeflow-update.sh status`).
- Mission : DAG persistant sur fichier (`dag.sh --file=F`, `.planning/MISSION-*.dag.json`) + lock de driver (`.planning/DRIVER.lock*`, gitignoré).
- Lab `cycles-v1` : état dérivé du disque, jamais déclaré (`recalc-planning.sh`, cache `.recalc-cache.json`).

## Key Abstractions

**Module** : unité toggable auto-décrite (triade `VERSION` + `module.json` + `CHANGELOG.md`). Types observés : agent+skills, single-skill+scripts, doc-only, agents+rules, skill+script+config.

**Scope** : cible d'install (`VF_SCOPE` ∈ user|project|local) résolue en `TARGET_ROOT` par l'engine — un seul scope partagé par toutes les briques d'une install.

**Hooks de gouvernance par module** : chaque module qui gouverne livre un `hooks/hooks.json` mergé par `merge-hooks.sh` — `plugin/conductor/hooks/hooks.json`, `plugin/planning-core/hooks/hooks.json`, `plugin/consolidator/hooks/hooks.json`, `plugin/software-architecture/hooks/hooks.json`, `plugin/infrastructure-audit/hooks/hooks.json`, `plugin/dev-orchestrator/hooks/hooks.json`. Contrat de sortie et inventaire (31 entrées) : `docs/HOOKS-CONTRAT-SORTIE.md`.

**Armement d'un gate** : état (`observe` | `armed`) porté par une constante du code livré, jamais par la configuration du lab ; un gate se désarme par une dérogation nominative, pas par un drapeau.

**Adhésion `cycles-v1`** : seule condition qui active le moteur par cycles et ses gates ; hors adhésion, silence total.

**Blueprint de bundle** : les bundles gardent leurs blueprints d'origine dans `plugin/<bundle>/content/`.

## Entry Points

**`/vibeflow-install`** — `plugin/installer/SKILL.md` : première install, ajout/retrait de modules, scope, presets.

**`/vibeflow`** — `plugin/commands/vibeflow.md` : délègue à l'agent `vibeflow-conductor`.

**`/vf-update` · `/vf-audit` · `/vf-planning` · `/vf-calibrate` · `/vf-new-lab` · `/vf-notify`** — `plugin/commands/*.md` : commandes de gouvernance (PAS des verbes dev).

**Langage naturel dev/design** — agents `vibeflow-head` (`plugin/dev-orchestrator/AGENT.md`) et `vibeflow-design` (`plugin/design-orchestrator/AGENT.md`), auto-routés par leur `description`.

**Hook central** — `plugin/planning-core/scripts/planning-hook.sh` via la commande de `plugin/planning-core/hooks/hooks.json` : déclenché par le harnais à chaque outil du matcher, dans un lab adhérent seulement.

## Les gates machine

| Gate | Script | Déclencheur | Effet |
|---|---|---|---|
| Version sync (ADR-054) | `scripts/check-version-sync.sh` | CI `gates` | exit 1 si VERSION ≠ plugin.json / marketplace / badges / triades |
| Release tag | `scripts/check-release-tag.sh [--remote]` | `scripts/hooks/pre-push` (opt-in), CI (main) | exit 1 si VERSION sans tag/release |
| Chemins de machine | `scripts/check-machine-paths.sh` | CI `gates` | aucun chemin absolu de machine dans les fichiers versionnés |
| Baseline d'instructions (G-1) | `scripts/check-baseline-arbitrage.sh` | CI `gates` | rougit sur hausse de `.planning/instruction-budget-baselines.tsv` ou sentinelle `.planning/.*-armed` neutralisée sans arbitrage cité |
| Gate touché (G-2) | `scripts/check-gate-touche.sh` | CI `gates` | exige un trailer `Gate-Touche: <chemin> — <raison>` quand un gate, sa suite, le CI ou un hook change |
| Push sans PR (G-3) | `scripts/check-push-sans-pr.sh` | CI (push sur main) | alarme après coup |
| Affirmation non mesurée (G-4) | `scripts/check-affirmation-non-mesuree.sh` + `scripts/measure-server-rulesets.sh` | CI `gates` | interdit d'affirmer une protection serveur non mesurée (`.planning/server-rulesets-measurement.json`) |
| Budget d'instructions (ADR-029) | `plugin/conductor/scripts/check-instruction-budget.sh` | CI `gates` | ratchet par fichier d'agent |
| Agents natifs (ADR-044) | `plugin/conductor/scripts/check-agents.sh` (`--strict`, `--hook`, `--resolve-agents=strict`) | CI, SessionStart lab | frontmatter natif + description + model + memory |
| Skills par nature | `plugin/conductor/scripts/check-skills.sh` | suites `plugin/conductor/scripts/tests/`, lab | `vf-nature` valide |
| Écriture d'agent | `plugin/conductor/scripts/guard-agent-write.sh` | PreToolUse Write (lab) | bloque un agent non conforme |
| Consommateurs de planning | `plugin/conductor/scripts/check-planning-consumers-registered.sh` | CI `gates` | tout script citant un chemin de planning est recensé dans `plugin/conductor/references/workstream-planning-consumers.md` |
| Divergence de workstream | `plugin/conductor/scripts/check-divergence.sh` | CI, `scripts/hooks/post-merge` (opt-in) | split-brain détecté |
| Intégrité de l'état | `plugin/conductor/scripts/check-state-integrity.sh` | CI `gates` (fan-out par compartiment via `vf_ws_enumerate`, `--path` et `--file` toujours passés ensemble, Phase 41.1) | frontmatter de `STATE.md` sans régression ; rc=2 bénin sur un compartiment sans `milestone:` |
| Planning à jour (ADR-050/055) | `plugin/planning-core/scripts/guard-planning-updated.sh` | Stop hook (bloquant, exit 2) | session ne se ferme pas planning en dette |
| **Gates d'écriture de planning** | `plugin/planning-core/scripts/planning-hook.sh` | PreToolUse, lab `cycles-v1` | G1, G5, G6, G7, ROLE armés ; G2 avertit |
| **Canary des gates** | `plugin/planning-core/scripts/check-gates-alive.sh` | SessionStart (advisory), CI via `plugin/_internal/tests/test-planning-hook-installed.sh` | un gate qu'on croit vivant et qui ne l'est pas est rendu visible |
| Mémoire index-first (ADR-032) | `plugin/consolidator/scripts/guard-read-registres.sh`, `guard-bash-registres.sh` | PreToolUse Read/Bash | lecture registre sans index bloquée |
| Taille de fichier | `plugin/software-architecture/scripts/guard-file-size.sh` | hook | seuil 300 L |
| Moteur GSD / survie des exigences | `plugin/dev-orchestrator/scripts/check-gsd-engine.sh`, `check-requirements-survival.sh`, `check-capability-activation.sh` | SessionStart (`plugin/dev-orchestrator/hooks/hooks.json`), CI `gates` (`check-capability-activation`) | cohérence du moteur et du ledger |
| Intégrité infra | `plugin/infrastructure-audit/scripts/audit-infra.sh` | `/vf-audit`, SessionStart (14 j) | drift Anthropic, scripts |
| CI lab frais (Gate C) | `ci.yml` job `lab-frais` | push/PR | baseline installée dans un lab vierge, ses gates passent sans intervention |
| CI lab frais armé | `ci.yml` job `lab-frais-arme` | push/PR | as-installed : fermeture `dev-orchestrator` (9 modules), exec form (PORT-05), conditions Windows simulées |

## Architectural Constraints

- **Pas de runtime applicatif** : tout est bash + python3 inline (heredoc) + markdown. Le moteur Python de `recalc-planning.sh` et `planning-hook.sh` est embarqué en heredoc quoté (aucun `.py` posé par l'installeur). Portabilité Windows durcie par ADR-054 (préflight, sonde python3, CRLF via `.gitattributes`).
- **Source d'install = cache uniquement** : `vibeflow-update.sh sync` est un no-op.
- **Scripts installés à plat** dans `.claude/scripts/` du lab ; references sous `.claude/agents/<module>-references/`.
- **Densité (ADR-029)** : agents — avertissement dès 251 lignes, bloque au-delà de 300 ; skills ≤ 500, bootstrap ≤ 2000 tokens.
- **Jamais de fix sans validation humaine (ADR-031)** ; escalades humaines court-circuitent toute autonomie.
- **Un manager ne produit jamais (P3)** ; production dans les workers ; juges read-only.
- **Un écrivain = un worktree (ADR-064)** ; une session = un worktree.
- **Aucun chemin absolu de machine** dans un fichier versionné (`scripts/check-machine-paths.sh`) ; les relevés de rejeu affichent `~/…`.
- **Global state** : `.planning/DRIVER.lock*` (verrou de mission), `.planning/active-workstream` (compartiment par défaut), cache `.planning/.recalc-cache.json` d'un lab ; table d'armement dans les constantes de `plugin/planning-core/scripts/planning-hook.sh`.
- **Instance de planning-core non armée ici** : ce dépôt (non adhérent) ne voit jamais les gates ; ils se prouvent par les suites de `plugin/planning-core/scripts/tests/` et la CI `lab-frais-arme`.

## Anti-Patterns

### Recréer une couche de synonymes / façade de verbes

**What happens:** ajouter des commandes `/vf-code`, `/vf-test`… qui wrappent les briques gsd-*.
**Why it's wrong:** double routage, drift entre façade et briques (supprimé en v2.33.0).
**Do this instead:** enrichir la carte d'intention unique `plugin/dev-orchestrator/references/intent-routing.md`.

### Release sans tag, ou release pour de la doc

**What happens:** bump de `VERSION` mergé sans tag `vX.Y.Z`, ou release déclenchée par une PR de doc/planning/specs.
**Why it's wrong:** version non traçable, ou mise à jour qui ne contient rien (ADR-073).
**Do this instead:** `scripts/bump.sh` puis tag annoté + `bash scripts/check-release-tag.sh --remote` pour une évolution fonctionnelle seulement ; sinon merge sans release (cas de `planning-core` v2.9.0).

### Agent non natif ou non cloisonné

**What happens:** poser un agent sans description/model/memory, ou un juge avec Write.
**Why it's wrong:** jamais auto-routé, triche possible (`check-agents.sh`, Pattern 12).
**Do this instead:** frontmatter natif complet ; workers internes `vf-internal: true` ; templates dans `plugin/reference/content/methodology/templates/agents/`.

### Écrire `VERDICT.md` ou un fichier généré par outil

**What happens:** un agent fait `Write`/`Edit` sur `VERDICT.md`, `STATE.md`, `INDEX.md`, `derogations-gates.log` d'un lab `cycles-v1`.
**Why it's wrong:** G5 / G6 armés refusent ; contourner par `Bash` hors commande dédiée casse la traçabilité.
**Do this instead:** `poser-verdict.sh` pour un verdict, `recalc-planning.sh` pour l'état, `deroger-gate.sh` pour une exception nominative.

### Faire décider un gate par l'environnement ou la configuration du lab

**What happens:** lire un drapeau (`options.gates`, `phases_trace`) ou une variable d'environnement pour armer/désarmer.
**Why it's wrong:** un agent peut écrire ces drapeaux (P45-D-01, P45-D-12a) ; ils restent sans effet.
**Do this instead:** constante `ARMEMENT_*` du code livré, alignée sur la table de `plugin/planning-core/references/modele-cycles.md` et `TABLE_ATTENDUE` des suites.

### Armer un gate hors de l'ordre ou sans rejeu

**What happens:** passer `ARMEMENT_G1` à `armed` avant G6/G5, ou armer sans rejeu réel.
**Why it's wrong:** `armement_valide` refuse alors TOUT dans un lab adhérent ; exigence P45-D-03b (0 faux refus, 0 faux accept).
**Do this instead:** ordre `ORDRE_ETAPES`, un commit par étape, relevé par `rejeu-reel.sh`.

## Error Handling

**Strategy:** scripts bash `set -euo pipefail` (ou `set -u` pour les lanceurs de hook), helpers `log()`/`err()` (exit 1), sorties préfixées `[nom-du-script]`.

**Patterns:**
- Hooks non bloquants suffixés `|| true` dans les `hooks.json` ; les guards bloquants (Stop, PreToolUse) sortent en exit ≠ 0, **sauf** `planning-hook.sh`, qui refuse par `deny` JSON en code 0.
- Contrat de sortie des hooks à trois codes et silence de flux : `docs/HOOKS-CONTRAT-SORTIE.md` (un SAIN et un INDÉTERMINÉ ne se confondent jamais : patron à 4 codes de `check-gates-alive.sh`, `check-guard-health.sh`).
- Gate fail-closed dans un lab adhérent, silencieux ailleurs ; un journal impossible à écrire ne devient jamais un refus.
- Rapports typés d'agents : `statut` + `findings[{severity, action}]` — l'escalade `ask-user` est impérative.
- Engine : backups par module + commande `rollback`.

## Cross-Cutting Concerns

**Logging:** stderr préfixé par script (`[vibeflow-update]`, `[preflight]`, `[recalc-planning]`, `[planning-core]`) ; journal d'observation des gates sous le cache utilisateur (jamais le contenu écrit).
**Validation:** module.json comme contrat (deps, type) ; `check-agents` / `check-skills` en lint ; `check-version-sync` en cohérence ; `modele-cycles.md` tenu égal au code par R-REFERENCE.
**Traçabilité des arbitrages:** tout commit qui invoque une décision humaine nomme canal et date ; identifiants de décision préfixés par registre (`P45-D-05`, `PART-D-02`), `CLAUDE.md`.
**Protection du dépôt:** rulesets `main` (PR, 4 checks, branche à jour, revue code owner sur `.github/`, baseline, sentinelles `.planning/.*-armed`, `scripts/hooks/`) et tags `v*`, versionnés dans `.github/rulesets/` ; garde par défaut + trace, pas un verrou (ADR-072).
**Doctrine:** `plugin/reference/content/methodology/` (Core, 12 patterns, vocabulaire) chargée on-demand. Les ADR vivent dans `docs/ADR.md` (ADR-046 → ADR-075, 29 entrées).

---

*Architecture analysis: 2026-10-02*
