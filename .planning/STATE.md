---
gsd_state_version: 1.0
milestone: vf-routing
milestone_name: Routage fin & verbes VibeFlow
status: in_progress
stopped_at: "Phases 12 et 14 COMPLÈTES et publiées (tags v2.31.0 et v2.30.0). Phase 13 redéfinie le 2026-07-26 sans verbe-façade (bascule agentique v2.33.0) : plan 13-01 écrit et committé, à exécuter ; 13-02 (câblage agent) à planifier. Repo en v2.36.1."
last_updated: "2026-07-26"
last_activity: 2026-07-26
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 14
  completed_plans: 13
  percent: 67
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-26 — charte rouverte : 17 modules, D2/D6 renversées)

**Core value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.
**Current focus:** Phase 13 (Pont spec → feuille de route) — **redéfinie le 2026-07-26 sans verbe-façade** :
la capacité d'ingestion est portée par l'agent `vibeflow-dev` (bascule agentique v2.33.0). Le fait est
outillé par `discover-unintegrated-docs.sh` (plan 13-01, écrit, à exécuter) ; le câblage agent est le
plan 13-02 (à planifier).

## Current Position

Phase: 13 (Pont spec → feuille de route, ingestion portée par l'agent) — milestone vf-routing
Plan: 13-01 écrit et committé (découverte outillée, BRDG-02) — **non exécuté** (0 SUMMARY).
Status: In progress — prochaine action `/gsd:execute-phase 13`, puis `plan-phase` pour 13-02.
Last activity: 2026-07-26 (remise à l'heure du planning + redéfinition Phase 13)

**Phases 12 et 14 livrées et publiées sur `main`** :
- Phase 12 (Routage fin & verbes `/vf-*`) — 6/6 plans · release **`v2.31.0`**. Livrait 31 verbes et la
  rule de préséance ; **la façade `/vf-*` a été supprimée depuis en v2.33.0** (bascule agentique, spec
  `2026-07-25-suppression-facade-vf-design.md`) — subsistent la carte d'intention unique de
  `vibeflow-dev` et les skills `vf-auto` / `vf-dev`.
- Phase 14 (Frontière d'altitude `planning-core` / moteur GSD) — 7/7 plans · release **`v2.30.0`** ·
  **ADR-055** (renuméroté au merge : `ADR-054` était déjà pris par la portabilité Windows publiée en
  v2.29.0). 92 assertions vertes.

**Depuis la clôture des phases 12/14, 5 releases hors milestone** (v2.32.0 → v2.36.1) : enforcement CI,
bascule agentique, team-kernel transverse, 3 bundles métier matérialisés, recettes UAT, refonte README.
Versions modules au 2026-07-26 : dev-orchestrator v2.1.1 · design-orchestrator v1.2.1 ·
conductor v1.14.1 · planning-core v2.5.1 · consolidator v1.8.0.

Milestone `gsd-migration` (Phases 10-11) reste ouvert et **en attente** — chantier indépendant, non bloquant.
Milestone précédent memory-swarm-rnd **SHIPPÉ v2.28.0** (ADR-052 mémoire vivante + ADR-053 swarm).

Progress: [███████░░░] 2/3 phases (13 : 1 plan posé sur 2, 0 exécuté)

## Performance Metrics

**Velocity:**

- Total plans completed: 26+ (13 mesurés phases 1-6 ci-dessous + 6 en Phase 12 + 7 en Phase 14 ;
  le compteur automatique n'a jamais été alimenté — reconstruit le 2026-07-26)
- Average duration: ~6 min/plan (sur les 13 plans mesurés)
- Total execution time: non mesuré au-delà de la Phase 6

**By Phase:** *(mesures disponibles uniquement — phases 7, 8, 9, 12 et 14 non instrumentées)*

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
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

- 2026-07-26 : **Phase 13 redéfinie sans verbe-façade** — la phase était écrite autour de `/vf-ingest`
  et du cycle `vf-brainstorm → vf-ingest → vf-plan → vf-execute`, supprimés en v2.33.0. BRDG-01..03 et
  les critères de succès réécrits : ingestion portée par l'agent `vibeflow-dev`, découverte outillée
  (13-01). Plan 13-01 committé et réparé (corpus 8 → 9 documents, markup parasite purgé).
- 2026-07-25 : Milestone **gsd-migration** créé (VOC-02 promu). Phase 10 (Étude & faisabilité migration GSD)
  + Phase 11 (Intégration, GATE Phase 10) ajoutées à la feuille de route. Requirements GSDM-01..06.
- 2026-07-25 : Milestone **vf-routing** créé. Phase 12 (Routage fin & couverture complète des verbes `/vf-*`)
  + Phase 13 (Pont spec → feuille de route) ajoutées. Requirements VERB-01..05, BRDG-01..03.
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

- **2026-07-26 — Phase 13 sans verbe** (arbitrage Samuel) : pas de résurrection de la façade — le pont
  spec → feuille de route est un geste de l'agent `vibeflow-dev`, la découverte seule est outillée
  (ligne de coupe ADR-055 §3).
- **2026-07-25 — Programme d'audit croisé livré en 3 releases** (v2.32.0 → v2.34.0, rapports
  dans `reports/`) : (1) enforcement branché — CI, gates exit 3, scission ADR-031/ADR-056 ;
  (2) **bascule agentique** (arbitrage Samuel, spec
  `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`) — façade vf-* supprimée,
  dev-orchestrator v2.x, manager avec digest/next steps/hygiène doc, gouvernance proportionnée
  au profil ; (3) universalisation — team-kernel transverse (conductor), équipe design,
  content-bundle matérialisé `proposable:true`, pipelining N/N+1, lab express, ADR-057.
  Prolongé par **v2.35.0** : growth-bundle et business-pilot-bundle matérialisés à leur tour
  (quality-gate-client livré) — les 3 bundles métier sont réels, promesse multi-métier tenue.
  **v2.36.0** : recettes UAT réelles sur labs vierges (express ~11 min 30 ✓ ; protocole de
  mission exécutable par un agent tiers ✓) — 16 frictions corrigées, job CI « lab frais »
  (la baseline doit passer ses propres gates depuis un lab vierge).

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

- Exécuter le plan 13-01 (`/gsd:execute-phase 13`) — découverte outillée des documents non intégrés.
- Planifier 13-02 (câblage de l'ingestion dans `vibeflow-dev`) — `/gsd:plan-phase 13`.
- Arbitrer la divergence doctrine distribuée : intitulés P3-P8 de
  `plugin/reference/content/methodology/vocabulary/lexique.md` ≠ `VIBEFLOW_CORE.md` v4.2
  (« Specialiser » n'existe plus comme principe) — signalée le 2026-07-26, décision humaine requise.
- *(milestone `gsd-migration`, en attente)* Cadrer la Phase 10 (`/gsd:discuss-phase 10`) : inventaire
  surface d'impact GSD + caractérisation `@opengsd/gsd-core`.

### Blockers/Concerns

- Migration package GSD `get-shit-done-cc` → `@opengsd/gsd-core` : milestone `gsd-migration` (VOC-02),
  ouvert et **en attente** — non bloquant pour vf-routing. Le go/no-go de la Phase 10 dépend de la
  maturité/parité du package cible sur npm — à vérifier en premier.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-07-26
Stopped at: Remise à l'heure du planning (audit périmé) + redéfinition Phase 13 sans verbe
Resume file: none — reprendre par `/gsd:execute-phase 13`
