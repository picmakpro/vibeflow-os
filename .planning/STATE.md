---
gsd_state_version: 1.0
milestone: vf-routing
milestone_name: Routage fin & verbes VibeFlow
status: in_progress
stopped_at: "Phases 12 et 14 COMPLÈTES et publiées sur main — tags v2.31.0 (routage fin) et v2.30.0 (frontière d'altitude, ADR-055) poussés. Reste : Phase 13 (pont /vf-ingest) non cadrée."
last_updated: "2026-07-25"
last_activity: 2026-07-25
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 13
  completed_plans: 13
  percent: 67
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-04)

**Core value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.
**Current focus:** Phase 9 (memory-swarm-rnd) — spike GO → **ADR-052 VALIDÉ + IMPLÉMENTÉ**. Le `consolidator` gagne un **pilier 5 « Mémoire vivante »** (v1.6.0) : couche fichier-par-entrée `.claude/memory/knowledge/` à décroissance de confiance + supersession non destructive (`scripts/decay-pass.sh`, 27 tests, revue de code passée). **SHIPPÉ v2.28.0** (ADR-052 mémoire vivante + ADR-053 swarm : lock + DAG + rapports typés). Volet swarm implémenté et dogfoodé. Milestone Doctrine dev & consolidation **SHIPPED v2.20.0**.

## Current Position

Phase: 13 (Pont spec → feuille de route, `/vf-ingest`) — milestone vf-routing
Plan: aucun — phase non cadrée. Prochaine action `/gsd:discuss-phase 13` puis `plan-phase`.
Status: Not planned yet
Last activity: 2026-07-25

**Phases 12 et 14 livrées et publiées sur `main`** :
- Phase 12 (Routage fin & verbes `/vf-*`) — 6/6 plans · release **`v2.31.0`** · dev-orchestrator v1.8.1,
  design-orchestrator v1.1.0, conductor v1.12.2. 31 verbes dans `dev-orchestrator` (14 → 31), 2 dans
  `design-orchestrator`. Tests 25 OK / 0 KO / 1 SKIP (le SKIP est `vf-ingest`, attendu en Phase 13).
- Phase 14 (Frontière d'altitude `planning-core` / moteur GSD) — 7/7 plans · release **`v2.30.0`** ·
  **ADR-055** (renuméroté au merge : `ADR-054` était déjà pris par la portabilité Windows publiée en
  v2.29.0). planning-core v2.4.0. 92 assertions vertes.

Milestone `gsd-migration` (Phases 10-11) reste ouvert et **en attente** — chantier indépendant, non bloquant.
Milestone précédent memory-swarm-rnd **SHIPPÉ v2.28.0** (ADR-052 mémoire vivante + ADR-053 swarm).

Progress: [██████░░░░] 2/3 phases (13 non cadrée)

## Performance Metrics

**Velocity:**

- Total plans completed: 0
- Average duration: — min
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. dev-orchestrator | 0/5 | - | - |
| Phase 01-dev-orchestrator P01 | 10min | 2 tasks | 6 files |
| Phase 01 P02 | 10 | 2 tasks | 1 files |
| Phase 01-dev-orchestrator P03 | 12 min | 2 tasks | 2 files |
| Phase 01 P04 | ~6 min | 2 tasks | 13 files |
| Phase 01-dev-orchestrator P05 | ~10min | 2 tasks | 4 files |
| Phase 02-manifeste-resolveur P01 | 5min | 2 tasks | 8 files |
| Phase 02-manifeste-resolveur P02 | ~5min | 2 tasks | 2 files |
| Phase 03-engine-scope-aware P01 | 3min | 3 tasks | 2 files |
| Phase 03 P02 | 6min | 2 tasks | 2 files |
| Phase 04 P01 | ~1 min | 2 tasks | 3 files |
| Phase 04 P02 | 5min | 2 tasks | 3 files |
| Phase 05 P01 | 2 | 3 tasks | 5 files |
| Phase 06 P01 | 1min | 2 tasks | 2 files |

## Accumulated Context

### Roadmap Evolution

- 2026-07-25 : Milestone **gsd-migration** créé (VOC-02 promu). Phase 10 (Étude & faisabilité migration GSD)
  + Phase 11 (Intégration, GATE Phase 10) ajoutées à la feuille de route. Requirements GSDM-01..06.
- 2026-07-25 : Milestone **vf-routing** créé. Phase 12 (Routage fin & couverture complète des verbes `/vf-*`)
  + Phase 13 (Pont spec → feuille de route, `/vf-ingest`) ajoutées. Requirements VERB-01..05, BRDG-01..03.
  Devient le milestone actif ; `gsd-migration` reste ouvert en attente (chantiers indépendants).
- 2026-07-25 : **Phase 14** (Frontière d'altitude planning-core / moteur GSD) ajoutée au milestone vf-routing.
  Constat déclencheur : `vf-planning` et la chaîne GSD produisaient les mêmes fichiers dans le même dossier
  avec des frontmatters **incompatibles** (`planning_version` vs `gsd_state_version`) — deux moteurs de
  planning concurrents. Décision : ADR-055, frontière d'altitude (un projet = un seul moteur ; VibeFlow tient
  le lab et l'enforcement). Requirements ALTI-01..05, 6 plans sur 4 vagues, indépendante des Phases 12 et 13.
- 2026-07-25 : compteurs de `progress` corrigés — ils affichaient `total_plans: 0` alors que la Phase 12
  comptait déjà 6 plans dont 1 livré (12-01). Réel : 12 plans posés (6 en Phase 12, 6 en Phase 14), 1 livré.

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (D1–D6).
Recent decisions affecting current work:

- **2026-07-25 — Programme d'audit croisé livré en 3 releases** (v2.32.0 → v2.34.0, rapports
  dans `reports/`) : (1) enforcement branché — CI, gates exit 3, scission ADR-031/ADR-056 ;
  (2) **bascule agentique** (arbitrage Samuel, spec
  `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`) — façade vf-* supprimée,
  dev-orchestrator v2.x, manager avec digest/next steps/hygiène doc, gouvernance proportionnée
  au profil ; (3) universalisation — team-kernel transverse (conductor), équipe design,
  content-bundle matérialisé `proposable:true`, pipelining N/N+1, lab express, ADR-057.

- [Phase 1]: D4 — index 100% auto-généré, ordre pipeline documenté dans l'agent.
- [Phase 1]: D3 — install auto des deps, init projet sur confirmation seulement.
- [Phase ?]: Index GSD trié alphabétiquement pour diff déterministe + idempotence vérifiable (Plan 01-01)
- [Phase ?]: [Phase 1]: ensure-deps.sh utilise set -uo pipefail (sans -e) car les détections reposent sur des exit non-zéro normaux (Plan 01-02)
- [Phase ?]: [Phase 1]: Contrat de test VF_ENSURE_DRY_RUN=1 pour valider l'idempotence sans réseau (Plan 01-02)
- [Phase ?]: [Phase 1]: Modules AGENT — references sous .claude/agents/<mod>-references/ (D7), index régénéré à l'install via VF_INDEX_OUT (IDX-02) (Plan 01-05)
- [Phase ?]: [Phase 1]: Densité des .md mesurée par wc -l, jamais le contrôleur de taille générique qui ignore les .md (Plan 01-05)
- [Phase ?]: module.json: requires[] = prérequis module réels uniquement, ENGINE (vibeflow-update.sh) exclu
- [Phase ?]: Engine défaut LEGACY=project (rétro-compat ./.claude) ; skill /vibeflow-install passe toujours VF_SCOPE explicite (cohérence ID4)
- [Phase ?]: docs/<mod>/ doc-only laissé hors TARGET_ROOT (relatif au cwd projet)
- [Phase ?]: Plus de git clone/pull : source = cache local (require_cache) ; sync = no-op explicite
- [Phase ?]: ensure-deps scope-aware via VF_SCOPE (GSD --global/--local, Superpowers --scope), VF_ENSURE_FORCE dry-run only, defaut LEGACY user (ID4)
- [Phase ?]: Hook VibeFlow pointe directement le script bash; marqueur 1er lancement aligné sur registre engine scripts/.vibeflow-installed
- [Phase 06]: Garde-fou first-use placé avant la table de routage (point de décision router-vs-proposer)
- [Phase 06]: Séquence d'init non dupliquée : délégation au skill vf-init existant

### Pending Todos

- Cadrer la Phase 10 (`/gsd:discuss-phase 10`) : inventaire surface d'impact GSD + caractérisation `@opengsd/gsd-core`.

### Blockers/Concerns

- Migration package GSD `get-shit-done-cc` → `@opengsd/gsd-core` : désormais **milestone actif `gsd-migration`** (VOC-02). Le go/no-go de la Phase 10 dépend de la maturité/parité du package cible sur npm — à vérifier en premier.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-07-20T15:23:36.856Z
Stopped at: Phase 9 context gathered
Resume file: .planning/phases/VFDO-09-spike-transposition-jcode-m-moire-swarm/09-CONTEXT.md
