---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 05
subsystem: infra
tags: [github-rulesets, branch-protection, codeowners, ci, gh-api]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t (41-04)
    provides: PR de la phase (#90) mergée dans main, source JSON des rulesets et CODEOWNERS versionnés
provides:
  - deux rulesets GitHub actifs sur picmakpro/vibeflow-os (branche main id=23892920, tags v* id=23892922)
  - critère de succès 1 du ROADMAP Phase 41 atteint et prouvé par relecture serveur
  - D-02bis mesuré : bypass_actors = exactement Samuel (151974738) et Willy/picmakpro (203482067), mode always, sur les deux rulesets
affects: [41-06, 41-07, 41-08, 41-09, 41-11, 41-12, 41-13]

actuals:
  tokens: 9000
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Pose GitHub par source versionnée: git show origin/main:<fichier> | gh api -X POST ... --input - (jamais de JSON retouché à la main)"
    - "Relecture serveur systématique après toute écriture d'API (jamais supposer bypass_actors ou current_user_can_bypass)"

key-files:
  created: []
  modified:
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md

key-decisions:
  - "POSE-DECISION: option=poser — Willy, AskUserQuestion session principale, 2026-09-23 (fenêtre de preuves non encore annoncée à Samuel au moment de la décision)"
  - "Pas de merge d'origin/main dans la branche B des preuves malgré 27 commits atterris sur main pendant l'exécution : les sources des rulesets (.github/rulesets/*.json, .github/CODEOWNERS) sont inchangées sur cette plage, la pose lit origin/main directement (jamais l'arbre de travail de B)"

requirements-completed: [PROT-01]

coverage:
  - id: D1
    description: "Deux rulesets GitHub posés depuis la source mergée d'origin/main et conformes côté serveur (cible, 4 types de règle, 4 checks requis épinglés integration_id=15368, aucun check-release-tag requis, rules/branches/main effectif) — critère de succès 1"
    requirement: "PROT-01"
    verification:
      - kind: integration
        ref: "gh api repos/picmakpro/vibeflow-os/rulesets/23892920 et /23892922 — bloc de vérification jq comparant serveur vs origin/main:.github/rulesets/*.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-02bis mesuré, jamais supposé : les deux entrées bypass_actors User (151974738 samuel-neveugall, 203482067 picmakpro) relues en mode always sur les deux rulesets ; current_user_can_bypass de picmakpro relu always sur les deux ; M2-VERDICT: CONFORME"
    requirement: "PROT-01"
    verification:
      - kind: integration
        ref: "GET /repos/picmakpro/vibeflow-os/rulesets/{id} — comparaison bypass_actors consignés vs relus, current_user_can_bypass"
        status: pass
    human_judgment: false
  - id: D3
    description: "Effet de la pose sur les PR en vol rapporté sans y toucher : #93 (déjà mergée avant la pose), #96 et #98 (ouvertes, relues en lecture seule)"
    verification:
      - kind: integration
        ref: "gh pr view 93/96/98 — comparaison PR-EN-VOL-AVANT/PR-EN-VOL-APRES, mergedBy relu vs consigné"
        status: pass
    human_judgment: false

duration: ~50min (Task 1 à 17:18, Task 2+3 de 19:55 à 20:09, horodatages des commits)
completed: 2026-09-23
status: complete
---

# Phase 41 Plan 05: Décision de pose, pose des deux rulesets, relecture serveur Summary

**Willy décide « POSER MAINTENANT » ; l'exécutant pose depuis origin/main (deux appels d'écriture), relit les deux rulesets côté serveur — critère de succès 1 atteint, D-02bis mesuré CONFORME.**

## Performance

- **Duration:** Task 1 committée à 17:18 (agent précédent) ; cette session (Task 2 + Task 3) de 19:55:58 à 20:08:59 (~13 min)
- **Started:** 2026-09-23T17:18:28+02:00 (Task 1, agent précédent)
- **Completed:** 2026-09-23T20:08:59+02:00
- **Tasks:** 3/4 exécutées (Task 4 non déclenchée — `M2-VERDICT: CONFORME`, aucun `POSE-ECHEC:`)
- **Files modified:** 1 (`41-PREUVES.md`)

## Accomplissements
- `POSE-DECISION: option=poser decideur=Willy canal=AskUserQuestion-session-principale date=2026-09-23 fenetre_preuves_annoncee=non` consignée et committée avant tout appel d'écriture
- Deux rulesets posés depuis `origin/main` (source mergée, octet pour octet) : branche `main` (id 23892920), tags `v*` (id 23892922) — exactement deux appels `POST /rulesets`, aucun `POSE-ECHEC:`
- Critère de succès 1 du ROADMAP atteint : `gh api repos/picmakpro/vibeflow-os/rulesets` rend 2 rulesets actifs (contre `[]` avant)
- D-02bis mesuré CONFORME : les deux entrées `bypass_actors` relues sont exactement `User:151974738` (Samuel) et `User:203482067` (Willy/picmakpro), mode `always`, sur les deux rulesets ; `current_user_can_bypass` de `picmakpro` relu `always` sur les deux
- Accès aux rule suites mesuré (`picmakpro=ok`, liste vide — aucun contournement dans l'heure, attendu)
- PR en vol rapportées avant (`#93`) et après (`#93` MERGED avant la pose par `samuel-neveugall`, `#96` et `#98` apparues entre-temps, relevées en lecture seule) — aucune touchée par la phase

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Task 1: préalables de pose relus, PR en vol inventoriées, retour arrière écrit** - `3e1d44f` (docs, agent précédent)
2. **Task 2: décision explicite de Willy — POSE-DECISION consignée** - `ce35308` (docs)
3. **Task 3: pose des deux rulesets, relecture serveur, M-2, PR en vol après** - `21175ec` (docs)

**Plan metadata:** committée séparément après ce SUMMARY

_Task 4 (checkpoint conditionnel « si M2-VERDICT: ECART ou POSE-ECHEC: ») n'a pas été déclenchée : `M2-VERDICT: CONFORME`, aucun `POSE-ECHEC:`._

## Files Created/Modified
- `.planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md` - `POSE-DECISION:`, `POSE-BRANCHE:`, `POSE-TAGS:`, `POSE-BYPASS-RELU:`, `POSE-MSG:`, `POSE-CONFORME:`, `M2:`, `M2-VERDICT:`, `ACCES-RULE-SUITES:`, `PR-EN-VOL-APRES:`, notes de rejeu `REJEU-GATES-41-05:` / `REJEU-TESTS-41-05:`

## Decisions Made
- **POSE-DECISION** : Willy tranche « POSER MAINTENANT » (AskUserQuestion session principale, 2026-09-23), sur pièce — inventaire des PR en vol (`#93` seule, `codeowners=oui` mais ouverte par `samuel-neveugall` donc pas de cas « auteur = seul code owner »), `main` verte, conséquences de D-02bis écrites sans les adoucir, retour arrière déjà écrit et committé. Samuel pas encore prévenu de la fenêtre de preuves au moment de la décision (`fenetre_preuves_annoncee=non`) — un message lui est préparé par la session principale, hors périmètre de cet exécuteur.
- **Pas de rebase/merge d'`origin/main` dans la branche B** malgré 27 commits atterris pendant l'exécution (dont une release `v2.65.0` et le merge de `#93`) : la pose lit `origin/main` directement à chaque appel (`git show origin/main:...`), jamais l'arbre de travail de B ; les fichiers source des rulesets et CODEOWNERS sont restés strictement inchangés sur toute cette plage (`git diff` vide), donc aucune divergence de source n'était possible. Garder B en retard de `main` limite la portée du travail de preuve au strict périmètre du plan.

## Deviations from Plan

### Constat documenté, non corrigé (hors périmètre — Rule 1/2 non applicables, SCOPE BOUNDARY)

**1. Deux échecs de suite de tests pré-existants, déjà connus, confirmés hors régression**
- **Trouvé pendant :** Task 3, rejeu `tests` demandé par l'action du plan après la pose
- **Constat :** `bash …/replay-ci-jobs.sh --job tests` rend 84 suites, 2 échecs — `plugin/_internal/runtime-adapter/tests/test-register-codex-agent-path-traversal.sh` (cas `T4 [majuscules]`, comportement lié à l'insensibilité à la casse du système de fichiers macOS de ce poste) et `plugin/conductor/scripts/tests/test-check-description-fidelity.sh` (36 KO, module Python `PyYAML` introuvable pour `python3` sur ce poste).
- **Pourquoi non corrigé :** les deux sont déjà consignés `open` dans `.planning/WINDOWS.md` (id 6 et 7, phase 41, plan 41-01), déjà caractérisés comme rouges préexistants reproduits à l'identique sur une extraction indépendante d'`origin/main`, hors périmètre de tout plan de la phase 41 (fichiers sans rapport avec les rulesets/CODEOWNERS), jamais neutralisés ni fixés sans validation humaine (ADR-031). L'installation de PyYAML est en outre explicitement exclue de l'auto-fix Rule 3 (installs de paquets = checkpoint humain, pas un auto-fix).
- **Confirmation indépendante que ce n'est pas une régression de la pose :** les 4 checks CI réels de la tête d'`origin/main` (`a962065`, source de la pose) sont `success`, `Suites de tests (découverte non vide)` comprise — l'écart est un artefact d'environnement local, pas un état réel du dépôt.
- **Fichiers concernés :** aucun fichier de ce plan (constat, pas une correction)
- **Consigné dans :** `41-PREUVES.md` (`REJEU-TESTS-41-05:`), déjà tracé au ledger `WINDOWS.md` id 6/7 (aucune nouvelle entrée créée — doublon évité)

---

**Total deviations :** 0 auto-fix (aucun changement de code) ; 1 constat documenté hors périmètre, déjà tracé.
**Impact on plan :** Aucun — `gates` rejoué sans écart (14/14) ; le rejeu `tests` révèle deux rouges d'environnement déjà connus et sans lien avec les rulesets, confirmés non régressifs par la CI GitHub réelle.

## Issues Encountered
- `origin/main` a avancé de 27 commits (dont la release `v2.65.0` et le merge de `#93`) entre la mesure `MAIN-VERTE-AVANT-POSE:`/`PR-EN-VOL-AVANT:` de la Task 1 et la pose de la Task 3 — sans effet sur la conformité de la source (fichiers `.github/rulesets/*.json` et `.github/CODEOWNERS` inchangés sur cette plage, vérifié par `git diff`) ; documenté dans `41-PREUVES.md`, aucune re-décision nécessaire.

## User Setup Required
None - aucune configuration de service externe requise (la pose est le geste externe lui-même, déjà exécuté sous le jeton admin de la session).

## Next Phase Readiness
- `POSE-BRANCHE: id=23892920` et `POSE-TAGS: id=23892922` disponibles pour les plans suivants (retour arrière, rule suites, revue code owner 41-06, M-1 41-07, contournement tracé M-3 41-08, push direct refusé M-4 41-09).
- `PR-EN-VOL-APRES: numeros=#93,#96,#98` borne les PR ouvertes tolérées par les plans 41-06 à 41-09 (en plus de leurs propres PR de preuve).
- Fenêtre de preuves ouverte côté serveur (rulesets actifs) ; Samuel reste à prévenir par la session principale (`fenetre_preuves_annoncee=non`) — hors périmètre de cet exécuteur, aucun blocage pour les plans suivants.
- Retour arrière déjà écrit et committé (`RETOUR-ARRIERE-ECRIT:`, Task 1) — disponible sans nouvelle rédaction si un plan suivant doit l'exercer.

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Completed: 2026-09-23*
