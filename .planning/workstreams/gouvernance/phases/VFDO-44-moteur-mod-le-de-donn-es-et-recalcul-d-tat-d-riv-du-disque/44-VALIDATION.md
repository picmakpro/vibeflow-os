---
phase: "44"
slug: "moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-27"
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash `test-*.sh` maison (PASS/FAIL comptés en shell, patron `check_exit()`) |
| **Config file** | aucune — découverte par glob CI (`find plugin scripts -type f -path '*/tests/test-*.sh'`, `.github/workflows/ci.yml:218`) |
| **Quick run command** | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` (nom délégué au planificateur) |
| **Full suite command** | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort \| xargs -I{} bash {}` |
| **Estimated runtime** | ~30-60 secondes (banc synthétique, pas de labs réels — ceux-ci tournent hors CI, D-06a) |

---

## Sampling Rate

- **After every task commit:** Run `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh`
- **After every plan wave:** Run `find plugin scripts -type f -path '*/tests/test-*.sh' | sort | xargs -I{} bash {}`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 secondes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-01-XX | TBD | TBD | MOTR-03 | — | Refus d'écriture sans `planning_version` adhérent, rien touché (cache compris) | unit (fixture) | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | ❌ W0 | ⬜ pending |
| 44-01-XX | TBD | TBD | MOTR-04 | — | Mode lecture seule — stdout uniquement, refus write-mode si GSD détecté | unit (fixture) | idem | ❌ W0 | ⬜ pending |
| 44-01-XX | TBD | TBD | MOTR-05 | — | Marqueur de clôture = fichier séparé, hash de `PLAN.md` stable | unit (fixture, hash avant/après création du marqueur) | idem | ❌ W0 | ⬜ pending |
| 44-01-XX | TBD | TBD | MOTR-07/MOTR-08 | — | 8 états + `indéterminé` sur les 4 contradictions D-08 | unit (banc synthétique, D-06) | idem, fixtures sous `scripts/tests/fixtures/recalc-bench/` | ❌ W0 | ⬜ pending |
| 44-01-XX | TBD | TBD | MOTR-10 | — | Sortie déterministe (byte-identique sur 2 recalculs) | unit (diff de deux runs successifs) | idem | ❌ W0 | ⬜ pending |
| 44-01-XX | TBD | TBD | MOTR-11 | — | `cloture.log` append-only, jamais réécrit ni supprimé | unit (mutation rouge : tenter une réécriture, vérifier le refus/l'absence de perte) | idem | ❌ W0 | ⬜ pending |
| 44-01-XX | TBD | TBD | MOTR-13 | — | Incrémental par hash : `touch` sans effet, contenu modifié détecté même mtime restauré | unit (les deux sens, D-13) | idem | ❌ W0 | ⬜ pending |
| 44-01-XX | TBD | TBD | MOTR-16/MOTR-17 | — | Jumeaux négatifs + mutation rouge tracée par état, banc seul gate en CI | CI (découverte auto) | `.github/workflows/ci.yml` job `tests` | ✅ (mécanisme déjà en place, seule la suite manque) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `plugin/planning-core/scripts/tests/test-recalc-planning.sh` — couvre MOTR-01 à MOTR-17
- [ ] `plugin/planning-core/scripts/tests/fixtures/recalc-bench/` — arborescence synthétique versionnée (D-06), au moins 18 cas nommés (8 états + 4 contradictions D-08 + 3 dérogations × avec/sans auteur)
- [ ] Framework install : aucun — `python3`/`bash` déjà présents partout sur ce poste et en CI

*Pas de gap sur l'infrastructure CI elle-même : le mécanisme de découverte des suites `test-*.sh` est déjà en place et ne nécessite aucune modification de `.github/workflows/ci.yml`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Passage en lecture seule sur les deux labs réels du poste (Jarvis Keystone, BusinessFlow-Lab) — temps + nombre d'`indéterminé`, non-écriture prouvée par empreinte sha256 avant/après | MOTR-17 (D-06a, D-06b) | Chemins machine-locaux (`~/jarvis-keystone`, `~/BusinessFlow-Lab`) — jamais dans une suite de CI ni dans le code livré (D-06a) | Rejouer le mode lecture seule sur chaque lab, capturer stdout, comparer l'empreinte de l'arbre (chemins + sha256) avant/après avec `cmp`, consigner temps + compte `indéterminé` dans le rapport de mission |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
