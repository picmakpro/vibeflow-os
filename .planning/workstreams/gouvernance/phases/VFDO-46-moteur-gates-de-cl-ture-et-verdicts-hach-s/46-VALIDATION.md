---
phase: "46"
slug: moteur-gates-de-cloture-et-verdicts-haches
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-03"
---

# Phase 46 — Validation Strategy

> Contrat de validation par phase. Le mapping détaillé exigence -> commande vit dans `46-RESEARCH.md` § Validation Architecture ; les commandes exactes (`<automated>` + `<fails_when>`) sont dans chaque `46-NN-PLAN.md`. Ce fichier est l'amorce (`draft`) : `gsd-validate-phase` le fait passer à `validated`.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Suites bash du module planning-core (`plugin/planning-core/scripts/tests/`), heredocs Python quotés, mutants par `make_script_mutant` |
| **Config file** | none (aucune installation) |
| **Quick run command** | la suite du plan touché, par sections (ex. `bash plugin/planning-core/scripts/tests/test-cloture-empreintes.sh`) |
| **Full suite command** | `test-planning-gates.sh`, `test-planning-hook-registered.sh`, `test-rejeu-gates.sh`, `test-recalc-planning.sh` + les 5 suites neuves (empreintes, gates de clôture, G4', D1, canary de juge) |
| **Estimated runtime** | gates ~223 s, hook-registered ~22 s, recalc ~40 s, rejeu-gates ~118 s ; suite du premier plan <= 600 s ; pré-filtre >600 s sous charge : par sections |

## Sampling Rate

- **After every task commit:** la suite du plan (zsh ET bash 3.2, sans `timeout`, sans `diff`)
- **After every plan wave:** suites de gates + registered + recalc + rejeu
- **Before `/gsd-verify-work`:** tout vert, mutants tous tués avec trace (assertion, attendu, obtenu)
- **Max feedback latency:** 600 s

## Per-Task Verification Map

| Plan | Vague | Exigences | Comportement sûr attendu | Type | Fichier test | Statut |
|------|-------|-----------|--------------------------|------|--------------|--------|
| 46-01 | 1 | CLOT-01, 03, 05 | livrable vide/lien refusé à la pose ; 2 empreintes ; plafond 3 (code 65) | suite neuve | test-cloture-empreintes.sh | ❌ W0 |
| 46-02 | 1 | CLOT-12 | amendements de spec ; note ROADMAP 47 prête, ROADMAP.md intact | doc + git | (verify par chemin) | ❌ W0 |
| 46-03 | 2 | CLOT-01, 03, 04 | état `à clore`, cache v2, R4 « absent ou vide » | recalc | test-recalc-planning.sh | ✅ |
| 46-04 | 3 | CLOT-09, 11, 12 | une commande, 5 événements, n==37, canary | registered/canary | test-planning-hook-registered.sh, test-hook-exit-parc.sh | ✅ |
| 46-05 | 4 | CLOT-01, 02, 03, 09, 10 | G3/G4 observe, fail-closed, jumeaux + mutants | suite neuve | test-cloture-gates.sh | ❌ W0 |
| 46-06 | 5 | CLOT-06, 09 | G4' sortie brute, hors mode auto, agents Bash seulement | suite neuve | test-g4p-sortie-brute.sh | ❌ W0 |
| 46-07 | 6 | CLOT-07, 09, 11 | D1 FileChanged + réconciliation SessionStart | suite neuve | test-d1-surveillance.sh | ❌ W0 |
| 46-08 | 6 | CLOT-10 | rejeu `--etape=5/6`, unités synthétiques | rejeu | test-rejeu-gates.sh | ✅ |
| 46-09 | 7 | CLOT-08 | canary de juge, juge sans preuve | suite neuve | test-juges-canary.sh | ❌ W0 |
| 46-10 | 7 | CLOT-11 | 0 régression lab dev, coût mesuré | suite + mesure | test-planning-prefilter (section evenements) | ✅ |
| 46-11 | 8 | CLOT-10 | armement G3+G4 après checkpoint, 0/0 sur banc | checkpoint + rejeu | rejeu-gates.sh --etape=5 | ⬜ |
| 46-12 | 9 | CLOT-10, 12 | armement G4P après checkpoint, planning-core v2.10.0 sans release | checkpoint + rejeu | rejeu-gates.sh --etape=6 | ⬜ |

*Statut : ⬜ pending · ✅ infrastructure existante · ❌ W0 = à créer*

## Wave 0 Requirements

- [ ] `plugin/planning-core/scripts/tests/test-cloture-empreintes.sh` (46-01)
- [ ] `plugin/planning-core/scripts/tests/test-cloture-gates.sh` + `cloture-banc.txt` (46-05)
- [ ] `plugin/planning-core/scripts/tests/test-g4p-sortie-brute.sh` (46-06)
- [ ] `plugin/planning-core/scripts/tests/test-d1-surveillance.sh` (46-07)
- [ ] `plugin/planning-core/scripts/tests/test-juges-canary.sh` (46-09)

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Autorisation du rejeu réel étapes 5 et 6 sur Keystone/BusinessFlow | CLOT-10 | le mandat du 2026-09-30 ne couvre pas la 46 | checkpoint 46-11 T1 |
| Porte de G4' | CLOT-10 | décision humaine, lignes `G4P-AGENT` à l'appui | checkpoint 46-12 T1 |
| CI Linux de la PR | CLOT-12 | geste de Willy (comme GATE-15, Phase 45) | PR, hors plan |
| Note ROADMAP Phase 47 | CLOT-12 | geste du manager | texte prêt dans 46-NOTE-ROADMAP-47.md |

## Validation Sign-Off

- [ ] Toutes les tâches ont un `<automated>` + `<fails_when>` ou une dépendance Wave 0
- [ ] Continuité d'échantillonnage : jamais 3 tâches consécutives sans vérification automatisée
- [ ] Wave 0 couvre les références MISSING
- [ ] Pas de drapeau watch-mode
- [ ] Latence de feedback < 600 s
- [ ] `nyquist_compliant: true` posé après exécution

**Approval:** pending
