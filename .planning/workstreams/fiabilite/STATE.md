---
gsd_state_version: "1.0"
milestone: fiabilite-v1.0
milestone_name: « ce qui survit » — Phases 30-35 + Phases 18 et 25 héritées —
current_phase_name: Posture de protection du dépôt
status: executing
stopped_at: >-
  Phase 41.4 exécutée (11 plans + 3 corrections ciblées, 2026-10-06), PR en brouillon empilée sur
  #134 ; revue tour 3 gaps_found (4 majeurs auto-fix, budget de 3 tours épuisé, arrêt sur consigne).
  Ancien texte de ce champ : `git show 13a52c8f:.planning/workstreams/fiabilite/STATE.md`.
last_updated: "2026-10-06T00:00:00.000Z"
last_activity: 2026-10-06
last_activity_desc: >-
  Phase 41.4 exécutée (11 plans), PR en brouillon ; détail : § Current Position.
progress:
  total_phases: 16
  completed_phases: 12
  total_plans: 115
  completed_plans: 105
  percent: 75
current_phase: 41
---

# Project State

Corps historique archivé tel quel (SOBR-02, 2026-09-29) : `.planning/archives/state/fiabilite-STATE-corps-2026-09-29.md`
(trace et blob d'origine : `.planning/archives/INDEX.tsv`). Frontmatter = seule source des compteurs.

## Project Reference

See: .planning/PROJECT.md

**Core value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.

## Current Position

Phase: **41.4** (Emprunts Pocock) — exécutée, 11 plans + corrections ciblées A, B, C (2026-10-06), POCK-01..08
cochées, sonde réelle POCK-04 jouée dans les deux sens ; tour 4 (P414-D-23) fait : rebasée sur `origin/main`,
4 majeurs du tour 3 fermés. PR #135 en brouillon (revue `@picmakpro` requise : `ci.yml`) ; revue tour 4 : Standards
`passed`, Spec `gaps_found` sur 1 majeur de texte (M4-01 : CHANGELOG dev-orchestrator et ROADMAP disent encore la
sonde « à jouer »), budget de 4 tours épuisé. `current_phase` reste 41.
Antérieur (état de main, 2026-10-02) — phase **41.2** : exécutée, plans 01-06 + corrections ciblées 01-02, PR ouverte
en revue ; vérification human_needed (E1 + parcours réel). Les plans 41-07 à 41-13 sont confiés à Willy, hors clôture.
Next: correction de M4-01 (texte, sur feu vert), sortie du brouillon de #135, merge (#135 absorbe #134), clôture du
jalon `fiabilite-v1.0`.
Last activity: 2026-10-06 — mission `.planning/missions/2026-10-06-phase-41-4-emprunts-pocock.md`.

## Accumulated Context

### Decisions

Historique complet (jalons, décisions, arbitrages 2026-07 à 2026-09) : voir l'archive ci-dessus.

- 2026-10-01/02 — Phase 41.2 : P412-D-01 à D-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-10-01),
  P412-D-05 (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02) ; P412-D-04, D-06, D-07, D-08 =
  décisions du manager. Registre : `41.2-CONTEXT.md` du dossier de phase.
- 2026-10-06 — Phase 41.4 : P414-D-01..D-11, D-17..D-22 (arbitrage Samuel, AskUserQuestion session principale,
  2026-10-06) ; D-12..D-16 = décisions du manager ; interprétation de D-22 (axe `skipped` hors conjonction) à
  ratifier. Registre : `41.4-CONTEXT.md` du dossier de phase.

- 2026-10-02 — Plans 41-07 à 41-13 (chaîne des mesures de la protection serveur) confiés à Willy, hors clôture de `fiabilite-v1.0` (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Les confier à Willy » pour 41-07 à 41-09, puis « Toute la chaîne à Willy » pour 41-10 à 41-13) ; PROT-01 cochée le 2026-09-24 sur la pose des rulesets, complément attendu : mesure du refus réel d'un push direct (41-09, complément en 41-13) confiée à Willy ; 41-07 partiellement entamé (`PR-R-*`, 2026-09-24).

### Pending Todos

Voir l'archive ci-dessus (section `### Pending Todos`) ; rien de neuf ici tant que non tranché.

### Blockers/Concerns

Voir l'archive ci-dessus (section `### Blockers/Concerns`), dont la Phase 23 gelée derrière ses arbitrages.

### Quick Tasks Completed

Tableau complet dans l'archive (section `### Quick Tasks Completed`) ; les nouvelles lignes s'ajoutent ci-dessous.

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|

## Deferred Items

- Recette humaine WINDOWS #3 : `test_sim`/`build_sim`/`clean` contre un XcodeBuildMCP vivant, sur un lab iOS (open, 2026-07-31).
- Geste humain : secret `TRAFFIC_PAT` non posé, snapshot traffic dormant (quick 260815-tl6, 2026-08-15).
- Dette outillage WINDOWS #4 : `inject-mcp-tools.sh` ne valide pas l'existence d'un serveur cité (repris Phase 21).
- Clôture du jalon `fiabilite-v1.0` : ledger REQUIREMENTS.md à trancher par Samuel (constat 2026-09-24).

## Session Continuity

**Resume file:** .planning/workstreams/fiabilite/phases/VFDO-41.4-emprunts-pocock-disciplines-de-cadrage-de-revue-et-de-skills/41.4-CONTEXT.md

Last session: 2026-10-06 — Phase 41.4 exécutée (11 plans), PR en brouillon, 4 majeurs de revue ouverts.
