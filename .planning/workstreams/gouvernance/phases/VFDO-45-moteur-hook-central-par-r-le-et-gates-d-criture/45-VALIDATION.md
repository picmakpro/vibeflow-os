---
phase: "45"
slug: moteur-hook-central-par-r-le-et-gates-d-criture
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-29"
---

# Phase 45 — Validation Strategy

> Contrat de validation par phase (échantillonnage du retour pendant l'exécution). Dérivé de `45-RESEARCH.md` § Validation Architecture. Les suites nommées n'existent pas encore : elles sont créées par les plans (colonne « File Exists »).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash `*/tests/test-*.sh` du dépôt (`ok`/`ko`, assertion/attendu/obtenu, mutants à motif unique) |
| **Config file** | aucun ; découverte CI par `find plugin scripts -type f -path '*/tests/test-*.sh'` (ci.yml) |
| **Quick run command** | `bash plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` |
| **Full suite command** | boucle littérale à ≥ 2 éléments sur les suites de `45-RESEARCH.md` + `bash scripts/check-version-sync.sh` |
| **Estimated runtime** | ~60 secondes |

---

## Sampling Rate

- **After every task commit:** la suite du plan concerné (< 30 s)
- **After every plan wave:** boucle des suites de planning-core + `scripts/check-version-sync.sh` + `scripts/check-machine-paths.sh`
- **Before `/gsd-verify-work`:** suites de `plugin/planning-core/scripts/tests/`, `plugin/_internal/tests/`, `scripts/tests/` vertes ; gates de planning du compartiment rejoués à la main (`--file .planning/workstreams/gouvernance/STATE.md`)
- **Max feedback latency:** 60 secondes

---

## Per-Task Verification Map

Rempli par les plans (`45-NN-PLAN.md`) ; la correspondance exigence -> commande de référence :

| Requirement | Wave | Test Type | Automated Command | File Exists | Status |
|-------------|------|-----------|-------------------|-------------|--------|
| GATE-01/03/10 | voir plans | intégration + mutation | `bash plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` | ❌ W0 | ⬜ pending |
| GATE-02/04/05/06/07/08/11/13 | voir plans | unitaire + banc | `bash plugin/planning-core/scripts/tests/test-planning-gates.sh` | ❌ W0 | ⬜ pending |
| GATE-09 | voir plans | croisé | `bash scripts/tests/test-role-hook-vs-check-agents.sh` | ❌ W0 | ⬜ pending |
| GATE-12 | voir plans | as-installed | `bash plugin/_internal/tests/test-planning-hook-installed.sh` | ❌ W0 | ⬜ pending |
| GATE-14 | voir plans | régression | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | ✅ à modifier | ⬜ pending |
| GATE-15 | voir plans | gates | `bash scripts/check-version-sync.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` — extraction, arbre de labs, 6 modes de défaillance, 4 shells, dispatchs Agent et Task, chemins relatifs, mutations à quatre conditions (texte distinct et `sh -n`, témoin identique, verdict et non erreur de syntaxe, trace)
- [ ] `plugin/planning-core/scripts/tests/test-planning-gates.sh` (+ fixtures) — sémantique gate par gate, jumeaux négatifs, mutations
- [ ] `plugin/_internal/tests/test-planning-hook-installed.sh` — install réelle -> commande posée -> rejeu
- [ ] `scripts/tests/test-role-hook-vs-check-agents.sh` — oracle différentiel
- [ ] réécriture des tests `socle-signal` de `test-recalc-planning.sh` (GATE-14)
- [ ] outil de rejeu lecture seule et geste de rejeu réel à empreinte de tout l'arbre prise hors de l'outil (`rejeu-reel.sh`) + leur suite

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rejeu réel des gates sur les labs adhérents réels (comptes, faux refus) | GATE-13 | les labs réels sont machine-locaux, hors CI | lancer l'outil de rejeu lecture seule avec les chemins en argument ; joindre le rapport nominatif ; décision d'armement = Willy |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
