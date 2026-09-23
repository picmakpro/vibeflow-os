---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 14
subsystem: infra
tags: [ci, bash, git, gate, baseline, gitops, testing]

# Dependency graph
requires:
  - phase: VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions
    provides: ".planning/instruction-budget-baselines.tsv" (le corpus gardé), le patron de contrat
      de `check-instruction-budget.sh` et de sa suite, l'outil de rejeu `tools/replay-ci-jobs.sh`
provides:
  - "scripts/check-baseline-arbitrage.sh — garde G-1 (PROT-04) : hausse de la colonne INSTRUCTIONS
    de la baseline, ou neutralisation d'une sentinelle `.planning/.*-armed`, sans citation
    d'arbitrage conforme dans le commit non-merge propre à la branche"
  - "scripts/tests/test-check-baseline-arbitrage.sh — suite QUAL-01, 34 assertions, neuf mutants
    opposables (MUT-1 à MUT-9)"
  - "Étape `check-baseline-arbitrage` dans le job `gates` de `.github/workflows/ci.yml`, à six
    bascules de fixture isolées"
  - "Entrée CHANGELOG.md § Non releasé nommant G-1"
affects: [41-15, 41-16, 41-17, 41-18, 41-19]

# Actuals (#2632)
actuals:
  tokens: 16118
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Garde in-repo lisant l'historique git via `git show <ref>:<chemin>` plutôt que le disque,
      patron déjà utilisé par `check-divergence.sh` et `check-instruction-budget.sh`"
    - "Fixtures de test 100% jetables (`mktemp -d`, `git init -q -b main`, identité par `-c`),
      jamais le dépôt réel"

key-files:
  created:
    - scripts/check-baseline-arbitrage.sh
    - scripts/tests/test-check-baseline-arbitrage.sh
  modified:
    - .github/workflows/ci.yml
    - CHANGELOG.md
    - README.md
    - README.fr.md
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md

key-decisions:
  - "G-1 dérive sa base par `git merge-base HEAD <ref-main-résolue>`, jamais l'adjacence du
    journal — prouvé discriminant par MUT-4 (fixture à trois commits)"
  - "Seule la colonne INSTRUCTIONS est bloquante ; une hausse de la seule colonne LIGNES produit
    un avertissement non bloquant (`AVERTISSEMENT-LIGNES-EN-HAUSSE`), jamais de citation exigée
    — décision du manager, 2026-09-17"
  - "Retrait d'une ligne de baseline : trois cas selon l'existence de la cible à HEAD et la
    présence d'une citation sur le commit qui retire la ligne (règle finale du manager,
    2026-09-17, qui assouplit une version bloquante-sans-échappatoire d'abord retenue)"
  - "`scripts/` est l'outillage du dépôt, pas un module distribué : aucun bump de VERSION ni de
    module, trace au CHANGELOG uniquement"

requirements-completed: [PROT-04, QUAL-01]

coverage:
  - id: D1
    description: "scripts/check-baseline-arbitrage.sh — garde G-1 complète (13 verdicts, 5 codes
      de sortie, cascade de résolution de base nommée)"
    requirement: PROT-04
    verification:
      - kind: unit
        ref: "scripts/tests/test-check-baseline-arbitrage.sh (34 assertions PASS/FAIL/BRUYANT/SILENCE/USAGE/NEG)"
        status: pass
      - kind: other
        ref: "bash -n scripts/check-baseline-arbitrage.sh ; invocation sur le dépôt réel (rc 0, ligne decouverte:)"
        status: pass
    human_judgment: false
  - id: D2
    description: "scripts/tests/test-check-baseline-arbitrage.sh — suite QUAL-01, neuf mutants
      opposables MUT-1 à MUT-9, chacun avec trace rc_mutant/rc_original"
    requirement: QUAL-01
    verification:
      - kind: unit
        ref: "scripts/tests/test-check-baseline-arbitrage.sh (exit 0, 0 ko, 9/9 mutants TUE en forme canonique)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Étape `check-baseline-arbitrage` dans le job `gates`, six bascules isolées sur
      dépôt jetable reconstruit à chaque fois, avant la mesure du dépôt réel"
    requirement: PROT-04
    verification:
      - kind: integration
        ref: ".planning/phases/VFDO-40.1-.../tools/replay-ci-jobs.sh --job gates (11 étapes rejouées, rc 0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "CHANGELOG.md § Non releasé porte l'entrée G-1 ; VERSION racine et modules
      inchangés"
    verification:
      - kind: other
        ref: "awk sur CHANGELOG.md § Non releasé + VERSION (script de vérification du plan)"
        status: pass
    human_judgment: false
  - id: D5
    description: "O-3 (25-SECURITY.md) documentée partout comme « signalée et tracée », jamais
      « fermée » — limite de fond écrite en en-tête du script, de la suite et de l'étape CI"
    verification: []
    human_judgment: true
    rationale: "Absence d'un mot d'achèvement est une propriété textuelle relue par un humain,
      pas assertée par une commande — le vérificateur doit confirmer qu'aucun texte produit par ce
      plan n'associe O-3 à l'un des jetons interdits : racine « ferm » plus suffixe
      « é »/« ée »/« és »/« ées », ou racine « clo » plus suffixe « s »/« se »/« ses »/« sed »."
status: complete
duration: 2h05min
completed: 2026-09-18
---

# Phase 41 Plan 14: G-1 — garde CI de baselines du budget d'instructions Summary

**Garde in-repo bash `check-baseline-arbitrage.sh` qui rougit quand la colonne INSTRUCTIONS de
`.planning/instruction-budget-baselines.tsv` monte, ou qu'une sentinelle `.planning/.*-armed` est
neutralisée, sans citation d'arbitrage conforme (canal + date) — traite O-3 du `25-SECURITY.md`
en « signalée et tracée » faute d'accès admin, prouvée par 34 assertions et 9 mutants opposables,
câblée dans le job `gates` à six bascules de fixture.**

## Performance

- **Durée :** ~2h05
- **Démarré :** 2026-09-17 (session), terminé 2026-09-18
- **Tâches :** 3/3 complétées
- **Fichiers modifiés/créés :** 7 (2 créés, 5 modifiés)

## Accomplissements

- `scripts/check-baseline-arbitrage.sh` posé : 13 verdicts nommés (`CONFORME`,
  `HAUSSE-SANS-ARBITRAGE`, `HAUSSE-NON-IMPUTABLE`, `SENTINELLE-NEUTRALISEE`,
  `LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE`, trois `AVERTISSEMENT-*`, `PLAGE-VIDE`,
  `BASELINE-ABSENTE`, `BASELINE-CREEE`), 5 codes de sortie (0/1/2/3/64), base dérivée par
  `git merge-base`, citation vérifiée en FORME uniquement (mot-clé + deux virgules + date ISO).
- `scripts/tests/test-check-baseline-arbitrage.sh` : 34 assertions vertes (5 PASS + 1 régression,
  6 FAIL, 4 BRUYANT, 2 SILENCE, 3 USAGE, 4 contrôles négatifs) et les NEUF mutants exigés
  (MUT-1 à MUT-9), chacun avec sa trace canonique `rc_mutant=<x> attendu <x>, rc_original=<y>
  attendu <y>` — MUT-6 prouve la colonne LIGNES non bloquante, MUT-7/8/9 couvrent les trois cas du
  retrait de ligne.
- Étape `check-baseline-arbitrage` posée dans le job `gates` de `.github/workflows/ci.yml`, à SIX
  bascules isolées sur dépôt jetable reconstruit depuis zéro, avant la mesure du dépôt réel (patron
  `check-instruction-budget`).
- `CHANGELOG.md` § Non releasé : entrée G-1, aucune VERSION ni module bumpé (`scripts/` = outillage
  du dépôt).
- Rejeu complet des deux jobs CI (découverte automatique, jamais une liste recopiée) : `gates`
  rc 0, 11 étapes rejouées, 0 échec ; `tests` rc 0, 80 suites, 0 échec.

## Task Commits

Chaque tâche a été committée atomiquement (plus deux correctifs Rule 1 découverts pendant
l'exécution, voir « Déviations ») :

1. **Task 1 : script G-1 + étape CI à une bascule** — `6e7c727` (feat)
2. **Task 2 : suite QUAL-01, trois issues et neuf mutants** — `533bb4e` (test)
   - **[Rule 1] Correctif : attribution du commit fautif pour une sentinelle déjà vide** —
     `ab60315` (fix), découvert pendant Task 3, voir ci-dessous
3. **Task 3 : étape CI à six bascules, CHANGELOG, rejeu complet** — `555a6e9` (feat)
   - **[Rule 1/3] Correctif : compte de suites des README (79 → 80)** — `da8c6ae` (fix)

_Base de la garde de trace (`41-PREUVES.md`) : `f1d658957f7fe9c446b341bc447c19d6a0a0ed3a` —
mesurée avant toute écriture de ce plan (HEAD après le fast-forward de mise à niveau du
worktree, voir « Écart d'exécution » ci-dessous). `plan_head_before` (ledger de commits) : même
valeur. `commits` mesuré : 5._

## Files Created/Modified

- `scripts/check-baseline-arbitrage.sh` — garde G-1 (nouveau)
- `scripts/tests/test-check-baseline-arbitrage.sh` — suite QUAL-01 (nouveau)
- `.github/workflows/ci.yml` — étape `check-baseline-arbitrage` dans le job `gates` (six bascules)
- `CHANGELOG.md` — entrée G-1 sous § Non releasé
- `README.md`, `README.fr.md` — compte de suites 79 → 80 (correctif Rule 1/3)
- `.planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md` — section
  `## 41-14 — base de la garde de trace`

## Decisions Made

Voir `key-decisions` en frontmatter. Aucune décision hors du cadre déjà arbitré dans
`41-CONTEXT.md` / `41-14-PLAN.md` — ce plan implémente les arbitrages du manager du 2026-09-17
sans en rouvrir aucun.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Attribution du commit fautif pour une sentinelle déjà vide**
- **Trouvé pendant :** Task 3, en construisant la bascule CI 4/6 (sentinelle
  `.planning/.instruction-budget-armed`, elle-même un marqueur 0 octet dans ce dépôt réel).
- **Problème :** le parcours de commits cherchant le commit fautif d'une neutralisation de
  sentinelle exigeait une taille préalable NON NULLE (`prev_size -gt 0`) — condition correcte pour
  le cas « contenu vidé » (statut `M`) mais appliquée à tort aussi au cas « fichier supprimé »
  (statut `D`/`R`). Une sentinelle déjà vide à la base ne créditait jamais aucun commit : le
  message restait « commit indetermine » et une citation d'arbitrage pourtant conforme sur le
  commit qui retire le fichier n'était jamais lue — la garde rendait `rc 1` à tort même en
  présence d'une citation valide.
- **Correction :** la recherche de commit fautif distingue désormais les deux mécanismes par le
  `status` du diff (D/R = existence seule ; M = taille préalable non nulle exigée).
- **Fichiers modifiés :** `scripts/check-baseline-arbitrage.sh`, `scripts/tests/test-check-baseline-arbitrage.sh`
  (ajout du cas PASS 6, régression qui aurait détecté le défaut).
- **Vérification :** `bash scripts/tests/test-check-baseline-arbitrage.sh` (34/34, 9/9 mutants) +
  sonde manuelle dédiée (sentinelle déjà vide, citation conforme → rc 0).
- **Commit :** `ab60315`

**2. [Rule 1/3 - Bug/Blocage] Compte de suites des README désynchronisé**
- **Trouvé pendant :** Task 3, rejeu complet du job `gates` exigé par le `<verify>` de la tâche.
- **Problème :** `check-version-sync` rougissait (`README.md`/`README.fr.md` : « 79 suites » ≠
  réel 80) — conséquence directe et prévisible de l'ajout de `test-check-baseline-arbitrage.sh`
  par la Task 2 de ce même plan. Sans correction, le rejeu `gates` exigé par Task 3 restait rouge.
- **Correction :** `79 suites` → `80 suites` dans les deux README (aucun bump de VERSION ni de
  module — simple resynchronisation d'un compte cité en toutes lettres).
- **Fichiers modifiés :** `README.md`, `README.fr.md`.
- **Vérification :** `bash scripts/check-version-sync.sh` (rc 0) puis rejeu complet `gates` (rc 0,
  11/11 étapes vertes).
- **Commit :** `da8c6ae`

---

**Total déviations :** 2 auto-corrigées (2 bugs Rule 1, dont 1 également Rule 3 — bloquait le
verify de la Task 3).
**Impact sur le plan :** les deux corrections étaient nécessaires à la correction fonctionnelle de
la garde (déviation 1) et au vert du `<verify>` de la Task 3 (déviation 2). Aucune extension de
périmètre au-delà de ce que Task 3 exigeait déjà (rejeu complet, sans rouge contourné).

## Issues Encountered

**Écart d'exécution (à signaler, sans impact sur le résultat) :** le worktree assigné à cet
exécuteur avait été forké depuis `main` (`5238cba`), AVANT que les commits de planification de la
Phase 41 (branche `feat/phase-41-protection-depot`) n'y soient présents — les fichiers
`41-CONTEXT.md`, `41-14-PLAN.md` et `41-PREUVES.md` étaient absents du worktree au démarrage. Un
fast-forward propre (`git merge --ff-only feat/phase-41-protection-depot`, aucun commit créé,
`5238cba` → `f1d6589`) a été appliqué avant la Task 1 pour obtenir ces fichiers. C'est cette valeur
post-fast-forward (`f1d6589...`) qui est la HEAD mesurée par le « geste zéro » et inscrite comme
`BASE-TRACE-ARBITRAGE`, conformément à l'instruction du plan (« la pointe qui PRÉCÈDE le premier
commit de ce plan ») — aucun commit de ce plan n'a été committé avant cette mesure. À signaler au
manager pour la fusion : la branche de ce worktree part de `f1d6589` (déjà la tête de
`feat/phase-41-protection-depot` au moment du fork), pas de `main`.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- G-1 est posée, prouvée et câblée — la tranche verticale (script `scripts/`, suite
  `scripts/tests/`, étape du job `gates`, trace au CHANGELOG) que G-2 (plan 41-16) et G-3/G-4
  (41-17 à 41-19) réutiliseront est disponible.
- O-3 du `25-SECURITY.md` reste signalée et tracée : aucun texte produit par ce plan ne l'associe
  à un mot d'achèvement.
- `41-PREUVES.md` § `## 41-14 — base de la garde de trace` borne, pour toute la suite du périmètre
  sans admin, la plage que le contrôle de trace du plan 41-15 a le droit de juger
  (`f1d658957f7fe9c446b341bc447c19d6a0a0ed3a..HEAD`) — la section `## 41-01` reste intacte.
- Formule canonique (sonde de limite de fond, `check-aucune-fermeture.sh`, plan 41-15, mandat
  élargi du manager de mission, 2026-09-17) : cette garde peut être modifiée par la PR qu'elle
  juge — ajoutée ici mot pour mot après coup, pour que la sonde ne signale plus ce SUMMARY comme
  muet sur sa propre limite de fond.
- Aucun blocage connu pour 41-15/41-16.

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Plan: 14*
*Completed: 2026-09-18*

## Self-Check: PASSED
