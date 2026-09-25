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
| 43-01-T1 (tracer) | 43-01 | 1 | FABR-06, FABR-09 | T-43-06 | gate lit le manifeste à 7 listes, procédure sans les deux champs refusée, lab frais vert | unit (bash) + lab frais (HOME temporaire) | `bash plugin/conductor/scripts/tests/test-check-skills.sh` (T1-T5) ; `test-check-agents.sh` (T107) ; témoin `TRACER-SKILLS-OK` | ❌ W0 (créé par la tâche) | ⬜ pending |
| 43-01-T2 | 43-01 | 1 | FABR-06 | T-43-01, T-43-02, T-43-04 | valeurs malformées refusées, jamais un défaut silencieux | unit (bash) + mutation | test-check-skills.sh T6-T13, MUT-S1..S3 | ❌ W0 | ⬜ pending |
| 43-01-T3 | 43-01 | 1 | FABR-06 | T-43-05, T-43-07, T-43-08 | découverte, exclusions, symlinks, F13, --hook identiques à check-agents | unit (bash) + mutation | test-check-skills.sh T14-T21, MUT-SD1/SD2 | ❌ W0 | ⬜ pending |
| 43-02-T1 | 43-02 | 2 | FABR-07 | T-43-11, T-43-12 | écart déclaration/prose dans les deux sens, avertissement (exit 0), jamais refus | unit (bash) + mutation | test-check-skills.sh T22-T29, MUT-DR1/DR2 | ❌ W0 | ⬜ pending |
| 43-02-T2 | 43-02 | 2 | FABR-07 | T-43-11 | écart marqueurs/nature ; corpus réel mesuré, vert | unit (bash) + arbre réel | test-check-skills.sh T30-T32, MUT-DR3 ; `CORPUS-DERIVE fail=0` | ❌ W0 | ⬜ pending |
| 43-03-T1 | 43-03 | 2 | FABR-08 | T-43-20, T-43-21 | moteur interne pose vf-nature, ≤ 500 lignes | grep + gate `--file` + relecture | commandes de vérification de la tâche (`MOTEUR-FIN`) | ✅ fichier existant | ⬜ pending |
| 43-03-T2 | 43-03 | 2 | FABR-08 | T-43-20, T-43-22 | workflow templaté pose vf-nature, étape 4 intacte, mineure cohérente | grep + gate `--file` + relecture | `GATE rc=0`, `SKILL-CREATOR-VERSION-OK` | ✅ fichier existant | ⬜ pending |
| 43-04-T1 (tracer) | 43-04 | 1 | FABR-09 | T-43-32, T-43-33 | SKILL.md > 500 lignes refusé, découverte = find hors doc-only, CI inchangée | unit (bash) + mutation + dépôt réel | test-check-instruction-budget.sh SKILL-1..6, MUT-8..10 ; `REEL rc=0` | ❌ W0 (nouveaux cas) | ⬜ pending |
| 43-04-T2 | 43-04 | 1 | FABR-09 | T-43-30 | checkpoint:decision — option bootstrap arbitrée par Willy, citée | humain (bloquant) | — | n/a | ⬜ pending |
| 43-04-T3 | 43-04 | 1 | FABR-09 | T-43-30, T-43-31, T-43-34 | bootstrap mesuré et borné selon l'option ; baseline citée | unit (bash) + mutation + G-1 | BOOT-1..5, MUT-11 ; `REEL-BOOT rc=0` ; `G1 rc=0/3` | ❌ W0 | ⬜ pending |
| 43-05-T1 (tracer) | 43-05 | 2 | FABR-10 | T-43-43, T-43-45 | serveur nommé absent de l'union signalé jusqu'au journal d'installation | unit (bash) + lab frais (HOME temporaire) | test-inject-mcp-tools.sh T16, T32, T33 ; test-vibeflow-update.sh T55 ; `TRACER-MCP-OK` | ✅ suites existantes, cas ajoutés | ⬜ pending |
| 43-05-T2 | 43-05 | 2 | FABR-10 | T-43-40, T-43-41, T-43-42, T-43-44 | vf-mcp-tools malformée refusée à l'install et au gate | unit (bash) + mutation | T22a-d, T34, MUT-A ; T56 ; T108, T109, MUT-M1 ; `CORPUS-AGENTS fail=0` | ✅ suites existantes | ⬜ pending |
| 43-07-T1 | 43-07 | 3 | FABR-10 | T-43-60, T-43-62 | spec §1.2/§7.2 amendée, citation D-Q3, fusion écartée | grep | 4 comptes de la spec (ancienne formule à 0, les trois autres > 0) | ✅ | ⬜ pending |
| 43-07-T2 | 43-07 | 3 | FABR-10 | T-43-60, T-43-61 | dev-orchestrator en patch, aucun bump racine | grep + check-version-sync | `DEV-ORCH-VERSION-OK` ; fichiers de version racine touchés = 0 | ✅ | ⬜ pending |
| 43-06-T1 | 43-06 | 4 | FABR-10 (c) + docs | T-43-50, T-43-51 | vf-calibrate à deux clés, conductor en mineure | grep + check-version-sync | `CONDUCTOR-VERSION-OK` | ✅ | ⬜ pending |
| 43-06-T2 | 43-06 | 4 | tous | T-43-52 | rejeu complet, G-1, G-2, labs frais | rejeu | `REJEU-FIN`, `CORPUS-REEL fail=0`, `G2 rc=0`, `LAB-FRAIS-FIN-OK` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Table remplie par le planificateur le 2026-09-25 (plans 43-01 à 43-06) ; révisée le même jour : l'ancienne 43-05-T3 devient 43-07 (T1 spec, T2 version), 43-06 passe en vague 4.*

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
