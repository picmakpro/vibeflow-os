---
gsd_state_version: "1.0"
milestone: fiabilite-v1.0
milestone_name: « ce qui survit » — Phases 30-35 + Phases 18 et 25 héritées —
current_phase_name: Posture de protection du dépôt
status: executing
stopped_at: >-
  Phase 39 shipped - PR 62 - v2.60.0 (2026-09-14). Exécutée 2026-09-10 (3 plans, SUMMARY sur disque),
  revue ×3 + audit infra + juge frais sur le diff de correction post-revue (mitigation de sécurité
  incluse), hotfix PR #61 fusionné sans conflit (`5efe8d3`) et regroupé dans la même release sur
  arbitrage Samuel (AskUserQuestion session principale, 2026-09-14). Ship autorisé par Samuel
  (AskUserQuestion session principale, 2026-09-14) après reprise de session et rejeu des huit gates.
  Livré : conductor v1.35.0 (`check-divergence.sh` S2/S4a/S4b/S5, suite 17 cas dont 3 mutants, hook
  `post-merge` opt-in ancré `--git-common-dir`, étape CI), dev-orchestrator v2.20.4 (dispatch `--ws`
  explicite, traçabilité des arbitrages), `PART-01..09` gravées et cochées, `GSDA-19` superseded,
  ADR-069 amendé. **Dépôt volontairement NON partitionné** (D-02 = déclencheur de reprise, § Decisions).
  Réserves inchangées : premier run CI distant observé sur la PR #62 seulement ; le clone jetable
  prouve un mécanisme, pas un usage concurrent réel. Issue amont `init-progress` rédigée, jamais postée.
  **Note (2026-09-15, plan 34-06) : `current_phase` reste intentionnellement à 39 malgré l'exécution
  complète et la ledgerisation de la Phase 34 (numérotée AVANT 39 dans le ROADMAP, exécutée APRÈS) —
  même précédent que la Phase 23 (§ Roadmap Evolution du 2026-08-04) : ce champ, gaté en
  anti-régression par `check-state-integrity.sh`, ne peut décroître au sein du même jalon ; il suit
  la progression numérique séquentielle, pas le dernier geste chronologique. Le travail réel de la
  Phase 34 est documenté dans `## Current Position` et `### Roadmap Evolution` ci-dessous, jamais
  perdu — seul ce pointeur numérique reste sur sa valeur la plus haute atteinte.**
  **Note (2026-09-15, clôture documentaire Phase 25) : mêmes raisons — `current_phase` reste à 39**
  bien que la Phase 25 ait ses vagues 1-3 vertes sur `feat/phase-25-budget-instructions` (exécution
  des trois plans de `5583d3e` à `6638804`, puis clôture documentaire et ses correctifs au-delà —
  décompte volontairement non chiffré ici : un total écrit DANS le fichier qu'il compte est faux dès
  le commit qui le porte, défaut constaté puis fermé le 2026-09-15).
  **Aucune PR ouverte, aucun ratchet armé** : ni
  `.planning/.instruction-budget-armed` ni `.planning/instruction-budget-baselines.tsv` n'existent.
  Le plan 25-04 (calibration) reste un checkpoint bloquant-humain, précondition « Phase 40 livrée »
  fausse à ce jour — non préparé.
  **Note (2026-09-16, plan 25-04) : `current_phase` reste à 39 pour la même raison (anti-régression
  ADR-063). Le ratchet du budget d'instructions EST désormais armé** — `check-instruction-budget`
  armé le 2026-09-16, `.planning/.instruction-budget-armed` et `.planning/instruction-budget-baselines.tsv`
  existent ; la phrase précédente « aucun ratchet armé » décrit l'état du 2026-09-15.
last_updated: "2026-09-24T08:13:16.937Z"
last_activity: 2026-09-24
last_activity_desc: >-
  Phase 41 : rulesets posés (41-05, 2026-09-23) ; plan 41-06 exécuté le 2026-09-24 — revue code
  owner non observable depuis les deux comptes en contournement always, CO-VERDICT: ECART accepté
  et documenté (arbitrage Willy, AskUserQuestion session principale, 2026-09-24).
  Détail : § Current Position. Frontmatter borné à 60 lignes (check-dev-bootstrap).
progress:
  total_phases: 15
  completed_phases: 11
  total_plans: 94
  completed_plans: 84
  percent: 73
current_phase: 41
---

# Project State

Corps historique archivé tel quel (SOBR-02, 2026-09-29) : `.planning/archives/state/fiabilite-STATE-corps-2026-09-29.md`
(trace et blob d'origine : `.planning/archives/INDEX.tsv`). Frontmatter = seule source des compteurs.

## Project Reference

See: .planning/PROJECT.md

**Core value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.

## Current Position

Phase: **41.3** (Sobriété de méthode — ce qu'on crée, on le range) — en cours, vague 1 (plans 01-02).
Plan: 41.3-01 (STATE sous budget, stash exporté), 41.3-02 (outillage rangement, worktrees).
Status: executing — la Phase 41 (protection du dépôt) reste le pointeur numérique `current_phase`.
Last activity: 2026-09-29 — exécution de la vague 1 de la Phase 41.3 ; corps historique du STATE archivé.

## Accumulated Context

### Decisions

Historique complet (jalons, décisions, arbitrages 2026-07 à 2026-09) : voir l'archive ci-dessus.

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

**Resume file:** .planning/workstreams/fiabilite/phases/VFDO-41.3-sobri-t-de-m-thode-ce-qu-on-cr-e-on-le-range-inserted/41.3-CONTEXT.md

Last session: 2026-09-29 — Phase 41.3 planifiée (4 plans), vague 1 exécutée.
