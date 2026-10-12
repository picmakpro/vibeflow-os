---
phase: "47"
slug: moteur-baux-generationnels-et-jeton-monotone
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-12"
---

# Phase 47 — Validation Strategy

> Contrat de validation par phase. Le mapping détaillé exigence -> commande vit dans `47-RESEARCH.md` § Validation Architecture ; les commandes exactes (`<automated>` + `<fails_when>`) sont dans chaque `47-NN-PLAN.md`. Ce fichier est l'amorce (`draft`) : `gsd-validate-phase` le fait passer à `validated`.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Suites bash `*/tests/test-*.sh` avec sections Python embarquées (`ok`/`ko`, jumeaux négatifs, mutants tués pour leur raison) |
| **Config file** | none (découverte CI : `find plugin scripts -type f -path '*/tests/test-*.sh'`) |
| **Quick run command** | la suite du plan touché (ex. `bash plugin/planning-core/scripts/tests/test-baux-registre.sh`), par sections via `VF_BAUX_SECTIONS` |
| **Full suite command** | suites de `planning-core` + `bash plugin/conductor/scripts/tests/test-dag.sh` + `bash scripts/check-version-sync.sh` + `bash scripts/check-machine-paths.sh` |
| **Estimated runtime** | suite neuve < 120 s visée ; pré-filtre > 600 s sous charge : par sections |

## Sampling Rate

- **After every task commit:** la suite du plan (zsh ET bash 3.2, sans `timeout`, sans `diff`)
- **After every plan wave:** suites de `planning-core` + `test-dag.sh` + gates de dépôt, gates de planning rejoués à la main avec `--file .planning/workstreams/gouvernance/STATE.md`
- **Before `/gsd-verify-work`:** tout vert, mutants tous tués avec trace (assertion, attendu, obtenu)
- **Max feedback latency:** 600 s

## Per-Task Verification Map

Voir `47-RESEARCH.md` § Validation Architecture (table Phase Requirements -> Test Map, BAIL-01..BAIL-10) ; les identifiants de tâche et commandes exactes sont portés par chaque PLAN.md.

Carte des quatorze plans (régénérée depuis les `47-NN-PLAN.md` le 2026-10-12) :

| Plan | Vague | Exigences | Suite ou commande de preuve |
|---|---|---|---|
| 47-01 | 1 | BAIL-01, BAIL-05 | `test-baux-registre.sh` (sections `cle`, `prise`, `tempete`, `outil`, `journal`, `ast`, `mut`) |
| 47-02 | 1 | BAIL-07 | `test-dag.sh` (T50 à T52, mutants par site) |
| 47-03 | 1 | BAIL-09 | `test-planning-gates.sh` (R-RECENSEMENT-ARMEMENT par ensembles, R-TABLE-07a à 07d) |
| 47-04 | 2 | BAIL-08 | `test-recalc-planning.sh` (R-RECALC-VERROU-01 à 04, R-RECALC-BAIL-01 à 05) |
| 47-05 | 2 | BAIL-02, BAIL-04 | `test-bail-gate.sh` (sections `prise`, `g6`) |
| 47-06 | 3 | BAIL-03, BAIL-10 | `test-bail-gate.sh` (sections `ecriture`, `banc`, `mut`) |
| 47-07 | 4 | BAIL-06 | `test-g2prime.sh` (section `base`, R-G2P-01 à 07) |
| 47-08 | 5 | BAIL-06 | `test-g2prime.sh` (sections `base` jusqu'à R-G2P-17, `banc`, `mut` du hook) |
| 47-09 | 6 | BAIL-06 | `test-g2prime.sh` (sections `miroir`, `gen` : propriété générative R-G2P-MIROIR-18, `mut` du recalcul), `test-recalc-planning.sh` (R-RECALC-BAIL-06) |
| 47-10 | 7 | BAIL-09, BAIL-10 | `test-planning-gates.sh` (section `cang`), `test-rejeu-gates.sh` |
| 47-11 | 8 | BAIL-10 | `test-planning-gates.sh` (sections `reference`, `table`), `test-baux-registre.sh` (R-BAUX-TRIO) |
| 47-12 | 8 | BAIL-10 | `scripts/check-version-sync.sh` |
| 47-13 | 9 | BAIL-09 | checkpoint humain, relevé `47-REJEU-ETAPE-7A.md` |
| 47-14 | 10 | BAIL-09 | checkpoint humain, relevé `47-REJEU-ETAPE-7B.md` |

Contrôles transverses de la phase (posés avec leur `--autotest`, rouges sous mutation) : `47-LIGNES-REQUISES.sh` (une ligne requise = `✓ <ID>` suivi d'un délimiteur, jamais un préfixe d'un autre identifiant) ; `47-CONTROLE-MARQUEUR-CHEMIN.sh` (chaque fichier gardé d'un commit couvert par le motif d'un trailer `Gate-Touche:` du même commit), en plus de `45-CONTROLE-MARQUEUR.sh`.

## Wave 0 Requirements

- [ ] `plugin/planning-core/scripts/tests/test-baux-registre.sh` — BAIL-01, 05 (47-01, 47-11)
- [ ] `plugin/planning-core/scripts/tests/test-bail-gate.sh` (+ fixture du banc) — BAIL-02, 03, 04, 10 (47-05, 47-06)
- [ ] `plugin/planning-core/scripts/tests/test-g2prime.sh` — BAIL-06 (47-07, 47-08, 47-09)
- [ ] `47-LIGNES-REQUISES.sh --autotest` et `47-CONTROLE-MARQUEUR-CHEMIN.sh --autotest` (dossier de la phase) — verts avant le premier plan
- [ ] cas T50-T52 dans `plugin/conductor/scripts/tests/test-dag.sh` — BAIL-07
- [ ] cas de concurrence dans `test-recalc-planning.sh` — BAIL-08
- [ ] extension des lieux qui recopient la liste des gates + test de recensement — BAIL-09

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rejeu réel en lecture seule (étapes 7a/7b) puis armement | BAIL-09 | Décision humaine bornée au moment d'agir (checkpoint, réponse par défaut = non) | Plans de checkpoint de la phase |
| CI Linux (flock sur dossier, ext4) | BAIL-01, 05, 07, 08 | Linux non disponible en local | CI de la PR (geste de Willy) |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 600s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
