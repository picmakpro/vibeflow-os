---
phase: "76"
slug: "tracabilite-au-cockpit"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-11"
---

# Phase 76 — Validation Strategy

> Contrat de validation par phase, extrait de `76-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash (`assert_eq`) + harnais Node ; mutants par copie + `mutsub.mjs` ; Chrome sans tête via `chrome-session.mjs` (exécution seulement) |
| **Config file** | aucun ; aide commune `plugin/cockpit/scripts/tests/socle-serveur.sh` (livrée par la 79, plan 79-02) |
| **Quick run command** | la suite du plan en cours : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-<chaine|decisions|memoire|collecte|route|page|panneaux>.sh`, ou `bash plugin/cockpit/scripts/tests/test-cockpit-questions-attente.sh` (plan 76-09) |
| **Full suite command** | les sept suites `test-cockpit-tracabilite-*.sh` et `test-cockpit-questions-attente.sh`, puis `test-cockpit-vendor.sh`, `bash scripts/check-version-sync.sh`, suites touchées par le retrait (`test-cockpit-projet-graphe.sh`, `test-cockpit-questions.sh`) |
| **Estimated runtime** | selon suite ; jamais lancée au moment du plan |

---

## Sampling Rate

- **After every task commit:** suite rapide de la tâche
- **After every plan wave:** suites touchées + `check-version-sync.sh`
- **Before `/gsd-verify-work`:** toutes les suites `plugin/cockpit/scripts/tests/test-*.sh` vertes
- **Max feedback latency:** une suite par tâche

---

## Per-Task Verification Map

Rempli par les plans (un témoin rouge par exigence, joué avant le code). Voir `76-RESEARCH.md` § « Phase Requirements → Test Map » pour les témoins et mutants par TRAC-01..12.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 76-XX-XX | — | — | TRAC-01..12 | T-76-* | voir plans | bash+node / chrome | voir plans | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Huit suites `plugin/cockpit/scripts/tests/test-cockpit-tracabilite-{chaine,decisions,memoire,collecte,route,page,panneaux}.sh` et `test-cockpit-questions-attente.sh` (TRAC-13) — créées chacune par son plan (76-01 à 76-07, 76-09), témoin rouge joué avant le code
- [ ] Fabrication du lab (ledger, dossiers de phase, ADR, CONTEXT à doublon, commits citants, mémoire)
- [ ] Mise à jour des assertions retirées : `test-cockpit-projet-graphe.sh` (P1.4, P5.3, R1.9, R2.9), `test-cockpit-questions.sh`

---

## Manual-Only Verifications

Toutes les vérifications de comportement ont un témoin automatisé ; la recette humaine (goût) est portée par la phase, pas par ce contrat.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
