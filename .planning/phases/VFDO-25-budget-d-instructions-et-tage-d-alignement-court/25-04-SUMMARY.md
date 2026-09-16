---
phase: 25-budget-d-instructions-et-tage-d-alignement-court
plan: 04
subsystem: infra
tags: [gate, ratchet, calibration, ledger]

requires: ["25-03"]
provides:
  - "Baselines du budget d'instructions gravées (.planning/instruction-budget-baselines.tsv, 31 fichiers)"
  - "Sentinelle .planning/.instruction-budget-armed posée dans le même commit — ratchet armé"
  - "conductor v1.37.1 (patch) : catalogue et CHANGELOG citent les valeurs gravées"
  - "BUDG-01, BUDG-02 cochés ; QUAL-01 tenu sur la Phase 25"
affects: [41]

actuals:
  tokens: non mesurable (exécution en direct par vibeflow-head, hors gsd-execute-phase)
  tasks: 3 (1 checkpoint + 2 auto)
  commits: 2 (tâche 2, tâche 3)
---

# Plan 25-04 — Calibration et armement du budget d'instructions

## Checkpoint (tâche 1)

Réponse **A — calibrer maintenant** : arbitrage Samuel, AskUserQuestion session principale (relais
SendMessage), 2026-09-16. Samuel a vu et accepté que deux fichiers soient au plafond exact de 250
lignes.

Faits présentés avant la décision, tous mesurés :
- Précondition : `git show origin/main:plugin/dev-orchestrator/AGENT.md | grep -c '^name: vibeflow-head'` → `1`.
- Gate non armé : exit 3, 31 fichiers, 0 dépassement, 0 non vérifiable, aucun fichier > 250 lignes.
- Aucune phase du milestone ne touche encore le corpus (AGTS-02 reportée, Phase 41 hors agents).

## Tâche 2 — gravure et armement (commit `a7f414a`)

- Corpus re-dérivé : 31 fichiers, même compte que 25-01.
- Mesure du script livré sur SHA `892f89a` : 3641 lignes, 487 instructions au total.
- Contrôle du plafond AVANT écriture : 0 fichier > 250 (`vf-dev-manager.md` et `validator/AGENT.md` à 250).
- Gate armé : exit 0 avant commit. Bloc `<automated>` du plan : `CALIBRATION-OK`.

**Déviation constatée et corrigée avant commit** : la première extraction du tableau est passée par
le filtre `rtk` (numéros de ligne injectés, lignes vides) — le gate armé a rendu `2` (31 entrées
orphelines). Il a fait exactement son travail. Régénération en `rtk proxy`, gate armé → `0`. Les
totaux provisoires issus de l'extraction corrompue (2996 / 418) ont été corrigés dans l'en-tête avant
commit ; seules les valeurs 3641 / 487 ont été committées.

## Tâche 3 — ledger

- REQUIREMENTS : BUDG-01/02 cochés avec date et preuve (liste et table de traçabilité) ; QUAL-01 ne
  liste plus la 25.
- ROADMAP : 25-04 coché, résultat de phase daté, Phase 25 cochée, ligne de progression 4/4.
- STATE (à la main, jamais `state record-session`) : `last_activity*`, note dans `stopped_at`, ligne
  `Phase:` unique, Session Continuity, « Ce qui reste fermé ». `current_phase` reste à 39 (ADR-063).
  Compteurs `progress` avancés du seul delta de ce plan (+1 plan, +1 phase, 91 %) — **pas
  re-dérivés** : le comptage disque (52 PLAN.md sur les 11 phases du jalon) ne recoupe pas le
  `total_plans: 55` hérité, et le gate interdit toute décroissance.
- Bloc `<automated>` du plan : `LEDGER-OK` (après correction d'une double ligne `^Phase:` que
  `check-state-integrity.sh` a rougie).

## Preuves

**Rejeu du job CI `gates`** (étapes extraites de `.github/workflows/ci.yml`, lancées en
`bash --noprofile --norc -e` comme le runner sans `shell:` explicite) : étapes 02 à 11 → rc=0 ;
étape 12 `check-release-tag` (main-only) → rc=0 localement. Le premier harnais en `-eo pipefail`
rendait l'étape 09 rouge à tort (substitution de commande sur un gate qui sort en 2 sur fixture non
calibrée) — invocation non fidèle, corrigée.

**Preuve rouge sur le dépôt armé** :
- Ligne ajoutée à `vf-dev-manager.md` → gate rc=1, `DEPASSEMENT-ADR029` (251 > 250) ; étape CI 09
  rc=1 avec `::error::... dépassement de baseline détecté sur le dépôt réel armé`.
- Puce impérative ajoutée à `vf-reviewer.md` → gate rc=1, `DEPASSEMENT-LIGNES+INSTR` (80/79, 10/9).
- Restaurations vérifiées par comparaison octet à octet ; gate et étape 09 → rc=0 après restauration.

Suite `test-check-instruction-budget.sh` : 30 ok, 0 ko après armement.

## Hors périmètre

Remédiation des fichiers chargés, budget des SKILL.md et du bootstrap, BUDG-03. Aucune PR, aucun
tag, aucune release : gestes humains.
