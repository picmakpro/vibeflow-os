---
phase: "80"
slug: trois-onglets-trois-formes-projet-en-couloirs-clavier-naviga
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-11"
---

# Phase 80 — Validation Strategy

> Contrat de validation de la phase pour l'échantillonnage pendant l'exécution. Source : `80-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash `assert_eq` + pilotes Node CDP (`chrome-session.mjs`) |
| **Config file** | aucune — découverte `find plugin scripts -path '*/tests/test-*.sh'` |
| **Quick run command** | `bash plugin/cockpit/scripts/tests/test-cockpit-<suite-du-plan>.sh` (depuis la racine de l'arbre) |
| **Full suite command** | `bash scripts/ci-suites-perimetre.sh --liste <base> HEAD \| while read -r s; do bash "$s" \|\| echo "FAIL $s"; done` puis les commandes du job `gates` de `ci.yml` |
| **Estimated runtime** | variable selon la suite navigateur (sous charge : plusieurs minutes) |

---

## Sampling Rate

- **After every task commit:** la suite du plan + `test-cockpit-vendor.sh`
- **After every plan wave:** périmètre `ci-suites-perimetre.sh` du diff de la vague
- **Before `/gsd-verify-work`:** périmètre complet + job `gates` (macOS local et CI Linux)
- **Max feedback latency:** la suite du plan seule, jamais la suite complète à chaque tâche

---

## Per-Task Verification Map

Rempli par les plans : chaque ligne FORM-xx porte un témoin rouge sur la base (trace collée) puis vert. La table des témoins attendus par exigence est dans `80-RESEARCH.md` § Phase Requirements → Test Map ; chaque PLAN.md en reprend ses lignes dans ses `<verify>`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| voir plans | — | — | FORM-01 à FORM-17 | T-80-xx | rendu par `SC.h()` / `textContent`, aucune requête neuve | navigateur / données / gates | suite neuve du plan | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extension de `ANNEAU` (X4) au `.card` d'un `g.node` focalisé — avant le plan FORM-01
- [ ] Ligne `vue=graphe` dans `naviguer()` + option de sortie — avant le plan des couloirs
- [ ] F5.2 étendu au dictionnaire neuf, s'il est créé

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| FORM-18 (S80-1 à S80-5) | FORM-18 | réouvertures d'arbitrage rangées « À Samuel » | plan non exécutable en l'état, décision de Samuel d'abord |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency bornée à la suite du plan
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
