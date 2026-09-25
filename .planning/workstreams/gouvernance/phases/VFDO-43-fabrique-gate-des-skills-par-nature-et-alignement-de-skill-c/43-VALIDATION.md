---
phase: "43"
slug: "fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-25"
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Suites bash maison (patron `plugin/conductor/scripts/tests/test-check-agents.sh` — `ok()`/`ko()`, jumeaux négatifs, mutation `cmp` prouvée rouge) — pas pytest/jest, jamais introduit dans ce dépôt pour les gates conductor |
| **Config file** | aucun — chaque suite est un script bash autonome, découvert par balayage CI |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-check-skills.sh` |
| **Full suite command** | rejeu des suites voisines listées en CI (`.github/workflows/ci.yml` : `check-agents`, `check-instruction-budget`, `check-blueprints`, `test-inject-mcp-tools`) |
| **Estimated runtime** | ~10 secondes par suite bash |

---

## Sampling Rate

- **After every task commit:** `bash plugin/conductor/scripts/tests/test-check-skills.sh` (ou la suite propre au fichier touché : `test-check-instruction-budget.sh`, `test-inject-mcp-tools.sh`)
- **After every plan wave:** rejeu des suites voisines déjà en CI (patron REJEU-FIN, Phase 42)
- **Before `/gsd-verify-work`:** suite complète verte, plus `check-gate-touche.sh` (G-2, trailer `Gate-Touche:` sur tout commit touchant un gate/sa suite/CI/un hook)
- **Max feedback latency:** ~10s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 0 | FABR-06 | — | `vf-nature: procedure` sans `ecrit:`/rubrique de juge refusé ; avec les deux, conforme | unit (bash) | `bash plugin/conductor/scripts/tests/test-check-skills.sh` | ❌ W0 (nouveau fichier) | ⬜ pending |
| TBD | TBD | TBD | FABR-07 | — | Écart déclaration/prose signalé en avertissement (exit 0), jamais en refus | unit (bash) | même suite, jumeau positif + jumeau négatif par marqueur | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | FABR-08 | — | `skill-creator`/`skill-creator-workflow` posent `vf-nature`, défaut « outil » | manuel — changement de prompt agentique, pas de code exécutable | — | n/a — pas un gate machine | ⬜ pending |
| TBD | TBD | TBD | FABR-09 | — | Budget SKILL.md (500L) + bootstrap (2000 tokens) refusés au-delà | unit (bash) | extension de `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh` | ❌ W0 (nouveaux cas) | ⬜ pending |
| TBD | TBD | TBD | FABR-10 | — | Grammaire `vf-mcp-tools` malformée refusée/signalée (a) ; serveur absent de l'union des scopes signalé (b) ; textes à une clé corrigés (c) | unit (bash) | extension de `bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` (durcir T16/T22) | ✅ suite existante, cas à durcir | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Table à remplir avec les vrais Task ID/Plan/Wave par le planificateur.*

---

## Wave 0 Requirements

- [ ] `plugin/conductor/scripts/tests/test-check-skills.sh` — nouvelle suite, patron `test-check-agents.sh` (Tn numérotés, jumeaux négatifs par invariant FABR-06/07, mutation prouvée sur au moins les invariants bloquants)
- [ ] Cas additionnels dans `test-check-instruction-budget.sh` pour la découverte SKILL.md (fixture > 500 lignes, fixture < 500 lignes) et pour la métrique bootstrap (fixture avec `description:` délibérément longue)
- [ ] Cas additionnels dans `test-inject-mcp-tools.sh` pour les durcissements (a)/(b), sans casser T16/T22 existants
- [ ] Manifeste `check-agents-manifest.json` étendu (7e liste) reste un JSON valide au schéma déjà validé par `charger_manifeste()` — décision de plan : réutiliser `charger_manifeste` telle quelle ou schéma frère, sans casser la validation des 6 listes agents

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|--------------------|
| `skill-creator`/`skill-creator-workflow` posent la question `vf-nature` | FABR-08 | Changement de prompt agentique (texte de SKILL.md), pas de code exécutable à faire tourner | Relire les deux `SKILL.md` modifiés : présence de la question `vf-nature`, défaut « outil » explicite dans le texte |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
