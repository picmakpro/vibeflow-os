---
phase: "42"
slug: "fabrique-manifeste-date-et-invariants-de-doctrine-du-gate-des-agents"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-23"
---

# Phase 42 — Validation Strategy

> Contrat de validation de la phase : échantillonnage des retours pendant l'exécution. Dérivé de
> `42-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suite bash maison `test-*.sh` (`ok`/`ko`, mutation prouvée par `cmp`) |
| **Config file** | aucun — découverte CI par `find plugin scripts -type f -path '*/tests/test-*.sh'` |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-check-agents.sh` |
| **Full suite command** | rejeu local des 3 étapes CI `check-agents` (`.github/workflows/ci.yml` ~l.252-320) + boucle des suites `test-*.sh` |
| **Estimated runtime** | ~5 s (quick) · plusieurs minutes (full) |

---

## Sampling Rate

- **After every task commit:** `bash plugin/conductor/scripts/tests/test-check-agents.sh`
- **After every plan wave:** les 3 étapes CI `check-agents` rejouées localement + `bash plugin/conductor/scripts/check-instruction-budget.sh`
- **Before `/gsd-verify-work`:** CI complète verte (`gates`, `tests`, `lab-frais`, `lab-frais-arme`) — `lab-frais` est le témoin direct de la copie du manifeste (D-16)
- **Max feedback latency:** 10 s pour la suite rapide

---

## Per-Task Verification Map

*Rempli par le planificateur (une ligne par tâche). Chaque tâche de gate écrit ses cas AVANT
l'implémentation (tdd) : la colonne « File Exists » dit si le fichier de test existe déjà, les cas
eux-mêmes naissent dans la tâche.*

| Task | Plan | Wave | Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|------|------|------|-------------|----------|-----------|-------------------|-------------|--------|
| 42-01-T1 (tracer) | 42-01 | 1 | FABR-01 | manifeste lu par le gate, posé par l'installeur, refus dans un lab sans manifeste ; T54 | E2E lab frais + unit installeur | commande TRACER-OK du plan ; `bash plugin/_internal/tests/test-vibeflow-update.sh` | ✅ (suite installeur) / manifeste à créer | ⬜ pending |
| 42-01-T2 | 42-01 | 1 | FABR-01 | harnais à manifeste du jour ; T77-T82 (absent, illisible, schéma, source unique, D-17, hook, garde) | unit + mutation de données | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ✅ | ⬜ pending |
| 42-01-T3 | 42-01 | 1 | FABR-01, FABR-05 | invocation nue sur cible ABSENTE hors --hook → INDÉTERMINÉ (D-20) ; T103, jumeau vert (cible présente vide, régime F13 inchangé). MUT-D20 posé en 42-04-T1 (helpers de mutation inexistants en vague 1) | unit + E2E lab frais (mutation vérifiée en 42-04-T1) | `bash plugin/conductor/scripts/tests/test-check-agents.sh` ; sonde D20-OK / D20-JUMEAU-VERT-OK ; LAB-HOOK-SILENCIEUX-OK | ✅ | ⬜ pending |
| 42-02-T1 | 42-02 | 1 | FABR-05 | vf-test-orchestrator interne (I3, D-18 deux dispatcheurs), corps inchangé, bump patch | integration (gate sur le module) | commande CORPUS-MTT-OK + awk INSTR-INCHANGE | ✅ | ⬜ pending |
| 42-02-T2 | 42-02 | 1 | FABR-05 | vf-business-manager SendMessage (I6, inconditionnel) — quality-gate-client (I5) SORTI, cf. 42-05-T2/T3 | integration + suite de module | CORPUS-BPB-OK ; garde anti-fusion (0 diff sur quality-gate-client.md) | ✅ | ⬜ pending |
| 42-02-T3 | 42-02 | 1 | FABR-05 | vf-content-manager SendMessage (I6, inconditionnel) — content-clarity-judge (I5) SORTI, cf. 42-05-T2/T3 | integration + suite de module | CORPUS-CB-OK ; garde anti-fusion (0 diff sur content-clarity-judge.md) | ✅ | ⬜ pending |
| 42-03-T1 | 42-03 | 1 | FABR-05 | vf-growth-manager SendMessage (I6, inconditionnel) — growth-quality-judge (I5) SORTI, cf. 42-05-T2/T3 | integration + suite de module | CORPUS-GB-OK ; garde anti-fusion (0 diff sur growth-quality-judge.md) | ✅ | ⬜ pending |
| 42-03-T2 | 42-03 | 1 | FABR-05 | vf-design-manager SendMessage (I6, T8 du module) — vf-design-judge (I5) SORTI, cf. 42-05-T2/T3 | integration + suite de module | CORPUS-DO-OK ; garde anti-fusion (0 diff sur vf-design-judge.md) | ✅ | ⬜ pending |
| 42-04-T1 | 42-04 | 2 | FABR-02, D-20 | T83-T90 (rétrogradation, INDETERMINE, bornes, date future, hook, portée D-05, garde), MUT-F1, MUT-F2 ; MUT-D20 (mutant de la ligne `cible_absente` posée en 42-01-T3, tué ici) | unit + mutation de code (QUAL-01) | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ✅ | ⬜ pending |
| 42-04-T2 | 42-04 | 2 | FABR-02 | `--manifest-freshness=strict` aux 4 appels CI | integration (rejeu CI + Gate C lab frais) | CI-REPLAY fail=0 ; GATE-C-OK ; YAML-OK | ✅ | ⬜ pending |
| 42-05-T1 | 42-05 | 3 | FABR-03 | I1, I4, I7 : T91, T91b (D-18, deux dispatcheurs), T92, T95, mutations réelles, MUT-I1, MUT-I4, MUT-I7 | unit + mutation (données réelles et code) | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ✅ | ⬜ pending |
| 42-05-T2 (checkpoint RÉELLEMENT bloquant) | 42-05 | 3 | — | arbitrage de Samuel sur D-08 (réponse à D-19) transcrit sous forme fixe dans 42-D19-MESURE.md, section `## Arbitrage D-08` ; ARBITRAGE-ABSENT arrête le plan entier ici (`human_needed`, T3 jamais atteinte) | manual + sonde machine | sonde `ARBITRAGE-*` (python3, regex ancrée sur la section, NFC), preuve sur 3 copies jetables | ✅ (artefact existe, section à ajouter) | ⬜ pending |
| 42-05-T3 | 42-05 | 3 | FABR-03, FABR-05 | Atteinte SEULEMENT si ARBITRAGE-MAINTENIR ou ARBITRAGE-RENONCER. I6 (T94, MUT-I6) TOUJOURS armé ; I5 (T93, MUT-I5, pose omitClaudeMd sur 4 juges + bump patch séparé) SEULEMENT si ARBITRAGE-MAINTENIR, DÉFINITIVEMENT retiré (FABR-03 partielle) si ARBITRAGE-RENONCER ; T96 (corpus réel + blueprints) | unit + mutation + integration, conditionnelle | suite + CI-REPLAY fail=0 (avec check-blueprints) ; I5-NON-ARME vérifié sur le code ET le frontmatter si RENONCER | ✅ | ⬜ pending |
| 42-06-T1 | 42-06 | 4 | FABR-04 | T97-T99 (récursion, exclusions, résolution), MUT-D1, MUT-D2, lab frais avec `-references` | unit + mutation + E2E lab frais | suite + LAB-RECURSIF-OK | ✅ | ⬜ pending |
| 42-06-T2 | 42-06 | 4 | FABR-03, FABR-05 | I2, I3 : T100-T102 (monde fermé réel muté), MUT-I2, MUT-I3 | unit + mutation + integration | suite + MONDE-FERME fail=0 | ✅ | ⬜ pending |
| 42-06-T3 | 42-06 | 4 | FABR-05 | conductor en mineure (variante « I5 retiré » si RENONCER — ce plan n'est jamais atteint sur ARBITRAGE-ABSENT), docs, T76 intact, rejeu complet, G-2, relevé Samuel (dont ci.yml de 42-04) | integration (toutes suites + gates) | REJEU-FIN sans ligne rouge ; G2 rc=0 ; ✓ T76 | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Nouveaux cas `T77+` dans `plugin/conductor/scripts/tests/test-check-agents.sh` (manifeste absent, illisible, périmé lenient/strict, I1-I7 avec mutation, découverte récursive + exclusion) — T77-T82 en 42-01-T2, T83-T90 en 42-04-T1, T91-T96 en 42-05, T97-T102 en 42-06 ; harnais à manifeste du jour (`mk_manifest`, `mk_gate_dir`) posé en 42-01-T2, helpers de mutation QUAL-01 (`make_gate_mutant`, `okmut`, `komut`) en 42-04-T1
- [ ] Cas de test de l'installeur prouvant qu'un `.json` sous `<module>/scripts/` est copié (D-16) — T54 de `plugin/_internal/tests/test-vibeflow-update.sh`, écrit rouge avant la boucle d'installeur (42-01-T1)

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
