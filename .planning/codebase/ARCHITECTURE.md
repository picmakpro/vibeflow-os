<!-- refreshed: 2026-07-26 -->
# Architecture

**Analysis Date:** 2026-07-26

## System Overview

vibeflow-os est le **repo de distribution** du plugin Claude Code « VibeFlow » (v2.36.1) :
un marketplace (`.claude-plugin/marketplace.json`) qui expose un plugin unique (`plugin/`)
composé de **17 modules toggables** + une infrastructure d'install (installer, engine
scope-aware, résolveur de deps, câbleur de hooks). Le repo lui-même n'exécute rien en
production : il est packagé par Claude Code dans un **cache** (`${CLAUDE_PLUGIN_ROOT}`),
puis l'engine copie les artefacts des modules choisis dans le `.claude/` d'un **lab**
(scope user / project / local).

```text
┌──────────────────────────────────────────────────────────────────────┐
│  Repo vibeflow-os (marketplace)                                      │
│  `.claude-plugin/marketplace.json` → source: ./plugin                │
├──────────────────────────────────────────────────────────────────────┤
│  plugin/  (le bundle distribué, manifest `plugin/.claude-plugin/     │
│  plugin.json`, skills: ./installer)                                  │
│  ┌──────────────┬──────────────────┬───────────────────────────────┐ │
│  │ 17 modules   │ installer/       │ _internal/                    │ │
│  │ <module>/    │ SKILL.md         │ vibeflow-update.sh (engine)   │ │
│  │ VERSION +    │ preflight.sh     │ resolve-deps.sh               │ │
│  │ module.json +│ build-module-    │ merge-hooks.sh (ADR-043)      │ │
│  │ CHANGELOG.md │ catalog.sh       │ retired-modules.txt           │ │
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
│  agents/<module>-references/  settings hooks mergés                  │
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
| Engine scope-aware | install / update / uninstall / rollback / status par module, source = cache (plus de git clone) | `plugin/_internal/vibeflow-update.sh` (838 L) |
| Résolveur de deps | Fermeture transitive des `requires` des module.json | `plugin/_internal/resolve-deps.sh` |
| Câbleur de hooks (ADR-043) | Merge les `hooks/hooks.json` des modules dans les settings du lab (placeholder `{{VF_SCRIPTS}}`) | `plugin/_internal/merge-hooks.sh` |
| Convergence des retraits | Nettoie les artefacts des modules retirés du parc | `plugin/_internal/retired-modules.txt` |
| Commandes plugin | Slash-commands de gouvernance (`/vibeflow`, `/vf-update`, `/vf-audit`, `/vf-planning`, `/vf-calibrate`, `/vf-new-lab`) | `plugin/commands/*.md` |
| Gates release repo | Discipline version/tag machine-enforced | `scripts/check-version-sync.sh`, `scripts/check-release-tag.sh`, `scripts/bump.sh`, `scripts/hooks/pre-push` |
| CI | 3 jobs : suites de tests, gates stricts, lab frais Gate C | `.github/workflows/ci.yml` |

## Les 17 modules (rôles et dépendances)

Chaque module = un dossier `plugin/<module>/` avec la triade `VERSION` + `module.json`
(name, version, type, description, `requires[]`) + `CHANGELOG.md` (+ `README.md`).

| Module | Version | Type | Rôle | requires |
|---|---|---|---|---|
| **conductor** | v1.14.1 | agent + skills + scripts + references | **Mandatory.** Orchestrateur méta / gardien du lab (`AGENT.md`), skills `vf-new-lab` (Lab Factory), `vf-update`, `vf-calibrate`. **Hôte du team-kernel** et des gates agents | planning-core, validator, skill-creator |
| **planning-core** | v2.5.1 | skill + references + scripts | Socle `.planning/` universel + altitude lab (compartiments, index, dette). **Frontière ADR-055** : ses hooks se retirent (`--defer-to-gsd`) quand un moteur GSD tient déjà le projet | — |
| **validator** | v1.3.1 | agent-only | Agent garant de l'alignement lab ↔ méthodologie (5 audits), incarné par `/vf-audit` | consolidator, infrastructure-audit, audit-architecture |
| **consolidator** | v1.8.0 | single-skill + scripts | Mémoire projet sur **5 piliers** (indexation, archivage, fusion, promotion, mémoire vivante ADR-052) + fork-config registres. Hooks de gouvernance mémoire ADR-032/043 | — |
| **skill-creator** | v1.0.2 | agent + skills | Pattern agent minimal + 2 skills composables pour créer des skills (canal parmi d'autres depuis ADR-057, plus « sole authorized channel ») | — |
| **audit-architecture** | v1.0.1 | single-skill + references | Méta-skill concepteur d'architectures d'audit multi-couches (ADR-036) | — |
| **infrastructure-audit** | v1.2.1 | single-skill + scripts | Garde-fou technique des labs : drift Anthropic, intégrité scripts (`scripts/audit-infra.sh`) | — |
| **software-architecture** | v1.5.2 | single-skill + rules + scripts | Doctrine AI-safe (SOLID, Clean Arch, gates Nyquist + Decision Coverage) + garde machine seuil 300 L (`scripts/guard-file-size.sh`) | — |
| **reference** | v2.5.1 | doc-only | Doctrine distribuée : Core v4.2 (`content/methodology/VIBEFLOW_CORE.md`), **12 patterns** (`content/methodology/patterns/01..12-*.md`), templates d'agents, vocabulaire | — |
| **dev-orchestrator** | v2.1.1 | agent + skills | **Modèle agentique (v2)** : agent `vibeflow-dev` (opus) route le langage naturel via la **carte d'intention unique** (`references/intent-routing.md`) vers les briques gsd-*/superpowers — la façade de verbes `/vf-*` est SUPPRIMÉE. Équipe de mission dev + skills `vf-auto`, `vf-dev` | conductor, design-orchestrator |
| **design-orchestrator** | v1.2.1 | agent + skills | Agent routeur `vibeflow-design`, skills `vf-design` / `vf-sketch`, équipe design sur le team-kernel. Compagnon de dev-orchestrator | conductor |
| **kpi-analyst** | v1.0.2 | agent + skill + scripts | KPIs métier déterministes → registre `KPIS.md` (jamais de chiffre inventé) | planning-core, consolidator |
| **mobile-test** | v1.0.1 | skill + script + config | Pipeline test mobile réel (Maestro, `scripts/mobile-test-run.mjs`). Expérimental | — |
| **mobile-test-team** | v1.4.0 | agents + rules | Boucle autonome test → corrige → re-test (`vf-test-orchestrator` + `vf-test-runner` / `vf-app-fixer`, Pattern 12) | mobile-test |
| **content-bundle** | v2.0.1 | agents + skill + scripts | Équipe content sur le team-kernel (`vf-content-manager` + strategist/writer/repurposer + juge `content-clarity-judge`), skill `vf-content`. `proposable: true` | conductor, planning-core, consolidator, audit-architecture, validator |
| **growth-bundle** | v2.0.1 | agents + skill + scripts | Équipe growth (`vf-growth-manager` + channel-strategist/copywriter/analyst + `growth-quality-judge`), Iron Law : envoi réel human-gated. `proposable: true` | idem content-bundle |
| **business-pilot-bundle** | v2.0.1 | agents + skill + scripts | Équipe business (`vf-business-manager`, nœuds par dossier client + workers commercial/delivery/finance + `quality-gate-client`). `proposable: true` | idem content-bundle |

**Graphe de dépendances (baseline)** : `conductor` (mandatory) tire `planning-core` +
`validator` + `skill-creator` ; `validator` tire `consolidator` + `infrastructure-audit` +
`audit-architecture`. Les 3 bundles métier et `dev-orchestrator` se posent par-dessus cette
baseline. Résolution : `plugin/_internal/resolve-deps.sh` (`install --with-deps`).

## Le team-kernel (hébergé par conductor, ADR-053)

Socle d'orchestration d'équipe transverse à tous les métiers, extrait du dev-orchestrator et
hébergé par le module mandatory. Doc : `plugin/conductor/references/team-kernel.md`.

| Brique | Implémentation | Garantie |
|---|---|---|
| Verrou de driver | `plugin/conductor/scripts/driver-lock.sh` (acquire / heartbeat / release, TTL + recovery, `mkdir` atomique) | une seule mission pilote à la fois |
| Plan de bataille (DAG) | `plugin/conductor/scripts/dag.sh` (init / add --deps / ready / mark / reopen) | dispatch de la frontière `ready` en parallèle ; `reopen` re-bloque les dépendants |
| Rapports typés (Pattern C) | `{ statut: passed\|gaps_found\|human_needed\|blocked, findings[], noeuds_debloques[] }` | fin du pilotage à la prose |
| Halt conditions (P11) | 5 codes — doctrine `plugin/reference/content/methodology/patterns/11-halt-conditions.md` | arbitrage humain en 30 s |
| Digest de mission | ≤ 30 lignes injectées dans chaque mandat | le disque fait foi |
| Cloisonnement par tools (P12) | juges sans Write/Edit, workers sans Task, `vf-internal: true` — linté par `check-agents.sh` | anti-triche machine-enforced |

**Qui s'y branche** :

| Équipe | Module | Manager | Workers | Juges |
|---|---|---|---|---|
| Dev (référence) | dev-orchestrator | `agents/vf-dev-manager.md` | `vf-coder.md` | `vf-reviewer.md`, `vf-auditer.md` |
| Design | design-orchestrator | `agents/vf-design-manager.md` | `vf-crafter.md` | `vf-design-judge.md` |
| Mobile | mobile-test-team | `vf-test-orchestrator` | `vf-app-fixer`, `vf-test-runner` | (le test EST le juge) |
| Content / Growth / Business | 3 bundles | `vf-content-manager` / `vf-growth-manager` / `vf-business-manager` | workers cloisonnés par bundle | juges frais read-only (rubric /100) |

Doctrine d'usage complète côté dev : `plugin/dev-orchestrator/references/mission-flow.md`
+ `mission-contracts.md` (seuil d'équipe `SEUIL_EQUIPE` : sous le seuil, pas de manager).

## Le modèle agentique (v2.33.0+, spec `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`)

- L'agent `vibeflow-dev` (`plugin/dev-orchestrator/AGENT.md`, opus, memory: project) détecte
  l'intention en langage naturel et invoque **directement** la brique outillée — **aucune
  couche de synonymes / façade de verbes** (leçon mémorisée : ne jamais la recréer).
- **Source unique de routage** : `plugin/dev-orchestrator/references/intent-routing.md`
  (carte intention → brique gsd-*/skill VibeFlow/agent d'équipe).
- Next steps déduits de la feuille de route (pont spec ↔ roadmap, phase `.planning/phases/13-pont-spec-feuille-de-route/`).
- Garde-fou first-use avant tout routage structurant ; hygiène documentaire déclenchée aux bons moments.
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` installe les briques gsd-* manquantes ;
  `build-gsd-index.sh` génère l'index des skills ; `inject-mcp-tools.sh` dérive l'allowlist MCP
  des exécutants (ADR-51).

**Agents natifs machine-enforced (ADR-044)** : tout agent posé passe
`plugin/conductor/scripts/check-agents.sh` — frontmatter natif Claude Code requis
(name, **description**, **model**, **memory**), skills déclarés existants, champs inconnus
rejetés. Un worker interne (Pattern 12) déclare `vf-internal: true` → pas de commande
d'incarnation générée (`plugin/conductor/scripts/generate-agent-commands.sh`).

## Data Flow

### Install (chemin principal)

1. L'utilisateur ajoute le marketplace → Claude Code copie `plugin/` dans le cache `${CLAUDE_PLUGIN_ROOT}` (`.claude-plugin/marketplace.json`)
2. `/vibeflow-install` (`plugin/installer/SKILL.md`) — UX à toggles, choix du scope
3. `preflight.sh` (prérequis durs) → `build-module-catalog.sh` (catalogue) → `resolve-deps.sh` (fermeture transitive)
4. `plugin/_internal/vibeflow-update.sh --scope <s> install --with-deps <module>` — copie les artefacts vers `TARGET_ROOT/.claude/` (user → `$HOME/.claude`, project/local → `./.claude`, local ajoute au `.gitignore`)
5. `merge-hooks.sh` câble les `hooks/hooks.json` des modules dans les settings du lab (`{{VF_SCRIPTS}}` → chemin réel des scripts)

### Update

1. `update-banner.sh` (SessionStart, conductor) signale une nouvelle version → `/vf-update` (`plugin/commands/vf-update.md` → skill `plugin/conductor/skills/vf-update/`)
2. `vibeflow-update.sh update --all` depuis le cache + `cleanup_retired_modules` via `plugin/_internal/retired-modules.txt`
3. Rollback possible : `vibeflow-update.sh rollback <module>` (backups)

### Release du repo

1. `scripts/bump.sh` — même numéro dans `VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, badges des 2 README + squelette CHANGELOG
2. `scripts/check-version-sync.sh` — gate de cohérence (5 sources + compteur de modules)
3. Merge sur main → tag annoté `vX.Y.Z` → `scripts/check-release-tag.sh --remote` (aussi câblé en `scripts/hooks/pre-push`, opt-in, et en CI)

**State Management:**
- Repo : `.planning/` (GSD : PROJECT/ROADMAP/STATE/phases) — non distribué.
- Lab : registre des modules installés + versions, tenu par l'engine (`vibeflow-update.sh status`).
- Mission : DAG persistant sur fichier (`dag.sh --file=F`) + lock de driver (dossier atomique).

## Key Abstractions

**Module** : unité toggable auto-décrite. Triade `VERSION` + `module.json` (`requires[]`,
`type`, `mandatory`/`proposable`) + `CHANGELOG.md`. Types observés : agent+skills,
single-skill+scripts, doc-only, agents+rules, skill+script+config.

**Scope** : cible d'install (`VF_SCOPE` ∈ user|project|local) résolue en `TARGET_ROOT` par
l'engine — un seul scope partagé par toutes les briques d'une install (cohérence ID4).

**Hooks de gouvernance par module** : chaque module qui gouverne livre un `hooks/hooks.json`
(événements PreToolUse/PostToolUse/SessionStart/UserPromptSubmit/Stop/SessionEnd) mergé par
`merge-hooks.sh` — voir `plugin/conductor/hooks/hooks.json`, `plugin/planning-core/hooks/hooks.json`,
`plugin/consolidator/hooks/hooks.json`, `plugin/software-architecture/hooks/hooks.json`,
`plugin/infrastructure-audit/hooks/hooks.json`.

**Blueprint de bundle** : les bundles gardent leurs blueprints d'origine dans
`plugin/<bundle>/content/` comme trace de conception lisible par `vf-new-lab` (Lab Factory).

## Entry Points

**`/vibeflow-install`** — `plugin/installer/SKILL.md` : premier lancement, ajout/retrait de modules, changement de scope.

**`/vibeflow`** — `plugin/commands/vibeflow.md` : délègue à l'agent `vibeflow-conductor` (créer un lab, vérifier, migrer, escalades).

**`/vf-update` · `/vf-audit` · `/vf-planning` · `/vf-calibrate` · `/vf-new-lab`** — `plugin/commands/*.md` : commandes de gouvernance (PAS des verbes dev — la façade dev `/vf-*` est supprimée).

**Langage naturel dev/design** — agents `vibeflow-dev` (`plugin/dev-orchestrator/AGENT.md`) et `vibeflow-design` (`plugin/design-orchestrator/AGENT.md`) auto-routés par leur `description`.

## Les gates machine

| Gate | Script | Déclencheur | Effet |
|---|---|---|---|
| Version sync (ADR-054) | `scripts/check-version-sync.sh` | pre-push (via check-release-tag), CI | exit 1 si VERSION ≠ plugin.json / marketplace / badges / compteur modules / triades |
| Release tag | `scripts/check-release-tag.sh [--remote]` | `scripts/hooks/pre-push` (main uniquement, opt-in), CI | exit 1 si VERSION racine sans tag `vX.Y.Z` |
| Agents natifs (ADR-044) | `plugin/conductor/scripts/check-agents.sh` (`--strict` en gate, `--hook` en SessionStart) | CI sur chaque `plugin/*/agents`, SessionStart lab, gate init | frontmatter natif + description + model + memory + skills existants |
| Écriture d'agent | `plugin/conductor/scripts/guard-agent-write.sh` | PreToolUse Write (lab) | bloque l'écriture d'un agent non conforme |
| Recherche avant debug (ADR-045) | `plugin/conductor/scripts/check-debug-research.sh` | SessionStart (advisory) | rappel doctrine |
| Planning à jour (ADR-050/055) | `plugin/planning-core/scripts/guard-planning-updated.sh` | Stop hook (bloquant) | session ne se ferme pas planning en dette |
| Mémoire index-first (ADR-032) | `plugin/consolidator/scripts/guard-read-registres.sh`, `guard-bash-registres.sh` | PreToolUse Read/Bash | lecture registre sans index bloquée |
| Taille de fichier | `plugin/software-architecture/scripts/guard-file-size.sh` | hook | seuil 300 L |
| Intégrité infra | `plugin/infrastructure-audit/scripts/audit-infra.sh` | `/vf-audit`, validator | drift Anthropic, scripts |
| CI lab frais (Gate C) | `.github/workflows/ci.yml` job 3 | push/PR | install baseline dans un lab vierge avec le vrai engine → ses propres gates doivent passer sans intervention |

## Architectural Constraints

- **Pas de runtime applicatif** : tout est bash + python3 inline (heredoc) + markdown. Portabilité Windows durcie par ADR-054 (préflight, sonde d'exécution python3, CRLF via `.gitattributes`).
- **Source d'install = cache uniquement** : `vibeflow-update.sh sync` est un no-op — plus aucun `git clone/pull` dans le chemin d'install.
- **Scripts installés à plat** dans `.claude/scripts/` du lab ; references sous `.claude/agents/<module>-references/`.
- **Densité (ADR-029)** : agents ≤ 250 lignes, skills ≤ 500, bootstrap ≤ 2000 tokens.
- **Jamais de fix sans validation humaine (ADR-031)** ; escalades humaines court-circuitent toute autonomie.
- **Un manager ne produit jamais (P3)** ; production dans les workers ; juges read-only.

## Anti-Patterns

### Recréer une couche de synonymes / façade de verbes

**What happens:** ajouter des commandes `/vf-code`, `/vf-test`… qui wrappent les briques gsd-*.
**Why it's wrong:** double routage, drift entre façade et briques — c'est exactement ce que la v2.33.0 a supprimé (spec `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`).
**Do this instead:** enrichir la carte d'intention unique `plugin/dev-orchestrator/references/intent-routing.md`.

### Release sans tag

**What happens:** bump de `VERSION` mergé sur main sans tag `vX.Y.Z` (vécu : v2.10→v2.16, juillet 2026).
**Why it's wrong:** version ni traçable ni installable par référence.
**Do this instead:** `scripts/bump.sh` puis tag annoté + `bash scripts/check-release-tag.sh --remote` (voir `CLAUDE.md`).

### Agent non natif ou non cloisonné

**What happens:** poser un agent sans description/model/memory, ou un juge avec Write.
**Why it's wrong:** jamais auto-routé, triche possible — c'est ce que `check-agents.sh` lint (ADR-044, Pattern 12).
**Do this instead:** frontmatter natif complet ; workers internes `vf-internal: true` ; templates dans `plugin/reference/content/methodology/templates/agents/`.

## Error Handling

**Strategy:** scripts bash `set -euo pipefail`, helpers `log()`/`err()` (exit 1), sorties préfixées `[nom-du-script]`.

**Patterns:**
- Hooks non bloquants suffixés `|| true` dans les `hooks.json` ; les guards bloquants (Stop, PreToolUse) sortent en exit ≠ 0.
- Rapports typés d'agents : `statut` + `findings[{severity, action}]` — l'escalade `ask-user` est impérative.
- Engine : backups par module + commande `rollback`.

## Cross-Cutting Concerns

**Logging:** stderr préfixé par script (`[vibeflow-update]`, `[preflight]`…).
**Validation:** module.json comme contrat (deps, type) ; check-agents en lint ; check-version-sync en cohérence.
**Doctrine:** `plugin/reference/content/methodology/` (Core v4.2, 12 patterns, vocabulaire) — chargée on-demand, jamais en bloc. Les ADR vivent dans `docs/ADR.md` (ADR-046 → ADR-057 dans le fichier courant).

---

*Architecture analysis: 2026-07-26*
