---
phase: "40"
slug: "vibeflow-head-head-of-minds-du-dev-orchestrator"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-15"
---

# Phase 40 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Suites bash maison, gabarit `ok`/`ko` (pas de framework tiers — patron `test-check-overlaps.sh`, `test-dev-orchestrator.sh`) |
| **Config file** | Aucun — chaque suite est un script exécutable autonome |
| **Quick run command** | `bash plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh` |
| **Full suite command** | Job CI `gates` : `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort` puis exécution de chaque suite [VERIFIED: .github/workflows/ci.yml:218] |
| **Estimated runtime** | ~5-15 secondes par suite bash (pas de framework à démarrer) |

---

## Sampling Rate

- **After every task commit:** Run la suite du module touché (`test-dev-orchestrator.sh` pour le
  renommage/AGENT.md/anti-alias, `test-check-mission-exit.sh` pour le gate, `test-check-overlaps.sh`
  pour la frontière ADR-057).
- **After every plan wave:** `find plugin scripts -type f -path '*/tests/test-*.sh' | sort` puis
  exécution intégrale — découverte CI automatique, aucun câblage manuel pour la nouvelle suite.
- **Before `/gsd-verify-work`:** Full suite (job `gates` de `ci.yml`) verte — rejouer les commandes
  réelles du job, jamais une liste recopiée d'un rapport (leçon du repo : « liste de gates ≠
  référence »).
- **Max feedback latency:** ~30 secondes (pas de compilation, suites bash directes).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 40-L1-* | L1 | 1 | HEAD-04 | — | Aucun alias `vibeflow-dev` ne survit dans `plugin/` hors CHANGELOG | unit (bash, grep + mutation) | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | ⚠️ fichier existe (nouveau cas à y ajouter) | ⬜ pending |
| 40-L1-* | L1 | 1 | HEAD-04 / ADR-057 | — | Ligne `vibeflow-dev\|gsd-next` renommée | unit (bash) | `bash plugin/conductor/scripts/tests/test-check-overlaps.sh` | ✓ existe (fixture à adapter) | ⬜ pending |
| 40-L2-* | L2 | 2 | HEAD-03 | — | Contrat E6 + décompte de coût documentés (gabarit + prose) | doc — aucune commande machine | — | — | ⬜ pending |
| 40-L3-* | L3 | 3 | HEAD-02 | — | Gate de sortie E1-E6, codes 3/0/4/64, mutation rouge prouvée (QUAL-01) | unit (bash) | `bash plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh` | ❌ Wave 0 — à créer avec le gate | ⬜ pending |
| 40-L4-* | L4 | 2 | HEAD-01 | — | Règle d'échelle, séquencement, contrat de sortie, économie dans `head-governance.md` ; AGENT.md ≤ 250 lignes | doc — aucune commande machine (cohérent avec `intent-routing.md`, seul `test-dev-orchestrator.sh` T14 vérifie son exhaustivité) | — | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh` — n'existe pas encore,
  naît avec le gate (QUAL-01 : mutation rouge prouvée dès la première vague, L3).
- [ ] Cas de test anti-alias dans `test-dev-orchestrator.sh` (fichier existant, nouveau bloc à
  ajouter, L1) — grep récursif `plugin/` hors `CHANGELOG.md`, mutation = réinjecter un alias
  `vibeflow-dev` et vérifier l'échec.
- [ ] Aucun framework à installer — tout l'outillage (bash, `ok`/`ko`) est déjà en place.

---

## Notes

- QUAL-01 (règle de preuve du milestone, `.planning/REQUIREMENTS.md` l.900-915) s'applique de plein
  droit au gate `check-mission-exit.sh` (L3) et au test anti-alias (L1) : un vérificateur incapable
  d'échouer ne compte pas.
- L2 et L4 sont de la prose de gouvernance/contrat — aucune commande automatisée n'est attendue
  pour eux ; leur preuve est une lecture de fichier (existence de section, comptage de lignes), pas
  un test au sens `ok`/`ko`.
- Source : `40-RESEARCH.md` §Validation Architecture (gsd-phase-researcher, 2026-09-15).
