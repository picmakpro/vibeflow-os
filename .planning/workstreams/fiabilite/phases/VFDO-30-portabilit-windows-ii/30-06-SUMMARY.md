---
phase: VFDO-30-portabilit-windows-ii
plan: 06

subsystem: infra
tags: [bash, hooks, claude-code, exit-codes, windows-portability, governance]

requires:
  - phase: VFDO-30-04
    provides: docs/HOOKS-CONTRAT-SORTIE.md (contrat de sortie, inventaire des 25 entrées), patron hook_exit()
provides:
  - hook_exit() dans 8 scripts gouvernance (conductor, consolidator, planning-core, infrastructure-audit) — silence interne traduit vers 0 sous --hook, aucun fragment hooks.json touché
  - Parité d'interface --hook (parsing + mutuelle exclusion --quiet) pour 4 scripts qui ne le portaient pas
  - Suite de parc scripts/tests/test-hook-exit-parc.sh — traduction + flux vérifiés séparément sur les 8 scripts, garde anti-vert-à-vide prouvée par mutation
affects: []

estimate:
  tokens: 100000
  raw_tokens: 100000
  tasks: 3
  confidence: low

tech-stack:
  added: []
  patterns:
    - "hook_exit() répliqué à l'identique (nom, contrat, place après le parsing d'arguments) sur 8 scripts hétérogènes — le JEU de codes traduits varie par script selon sa propre classification (silence vs signal), jamais le nom ni la place du point de traduction"
    - "say_diag() — même contenu qu'un say() existant mais explicitement sur stderr — réservé au SEUL diagnostic nominal (rien à signaler) quand say() écrivait déjà tout sur stdout sans distinction signal/silence"

key-files:
  created:
    - scripts/tests/test-hook-exit-parc.sh
  modified:
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/check-branch-claim.sh
    - plugin/conductor/scripts/check-workstream-pointer.sh
    - plugin/conductor/scripts/tests/test-check-workstream-pointer.sh
    - plugin/consolidator/scripts/check-registres.sh
    - plugin/consolidator/scripts/seed-registres.sh
    - plugin/planning-core/scripts/check-planning-state.sh
    - plugin/planning-core/scripts/detect-planning-debt.sh
    - plugin/infrastructure-audit/scripts/audit-infra.sh
    - plugin/conductor/VERSION
    - plugin/conductor/module.json
    - plugin/conductor/CHANGELOG.md
    - plugin/conductor/README.md
    - plugin/consolidator/VERSION
    - plugin/consolidator/module.json
    - plugin/consolidator/CHANGELOG.md
    - plugin/consolidator/README.md
    - plugin/planning-core/VERSION
    - plugin/planning-core/module.json
    - plugin/planning-core/CHANGELOG.md
    - plugin/planning-core/README.md
    - plugin/infrastructure-audit/VERSION
    - plugin/infrastructure-audit/module.json
    - plugin/infrastructure-audit/CHANGELOG.md
    - plugin/infrastructure-audit/README.md

key-decisions:
  - "check-agents.sh (doc 30-04 : « action = rien, déjà conforme ») a quand même reçu hook_exit() pour parité structurelle — la traduction 3→0 y était déjà obtenue par un `not hook` interne au bloc Python. Ce garde-fou a été déplacé au SHELL (où le processus rend la main) pour que le point de traduction soit un seul nommé, identique au reste du parc, sans changer le contrat interne du bloc Python."
  - "check-workstream-pointer.sh : le code 2 (NON VÉRIFIABLE) est classé silencieux et traduit — pas parce qu'il représente un échec du script, mais parce qu'il collisionnerait avec le code 2 RÉSERVÉ au blocage délibéré du harness (docs/HOOKS-CONTRAT-SORTIE.md §1) si jamais émis involontairement sous --hook."
  - "check-planning-state.sh et detect-planning-debt.sh n'ont, contrairement au reste du parc, AUCUN code « signal » déjà à 0 — tous leurs diagnostics (y compris le cas nominal) vivaient sur 1/2/3 et étaient tous écrits sur STDOUT via un say() non discriminant. Les codes advisory migrent vers 0 (signal émis normalement, §1 du contrat) ET le seul diagnostic vraiment nominal (rien à signaler) a été routé vers un say_diag() dédié sur stderr — sinon aucun cas silencieux (stdout vide) n'aurait été atteignable pour prouver le critère d'acceptation du plan sur ces deux scripts."
  - "check-registres.sh portait déjà --hook mais un chemin (`--strict --allow-empty` sur cible vide) n'était JAMAIS passé par la garde --hook — un vrai défaut de flux (stdout non vide, code inchangé) du même type que ceux corrigés au plan 30-04, corrigé dans ce plan plutôt que reporté."

requirements-completed: [PORT-03]

coverage:
  - id: T1
    description: "4 scripts gouvernance qui portent déjà --hook (check-agents.sh, check-branch-claim.sh, check-workstream-pointer.sh, check-registres.sh) traduisent leur silence sous --hook, sans qu'aucun fragment hooks.json n'ait bougé"
    requirement: "PORT-03"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh (81 OK / 0 KO)"
        status: pass
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-branch-claim.sh (18 OK / 0 KO)"
        status: pass
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-workstream-pointer.sh (24 OK / 0 KO, 3 cas mis à jour pour le nouveau contrat)"
        status: pass
      - kind: unit
        ref: "plugin/consolidator/scripts/tests/test-check-registres.sh (15 OK / 0 KO)"
        status: pass
      - kind: unit
        ref: "scripts/tests/test-hook-exit-parc.sh (sous-ensemble des 4 scripts, mutations m1/m2)"
        status: pass
    human_judgment: false
  - id: T2
    description: "4 scripts sans --hook (seed-registres.sh, check-planning-state.sh, detect-planning-debt.sh, audit-infra.sh) gagnent la parité d'interface + hook_exit(), prêts pour la migration en forme exec, sans qu'un seul fragment n'ait bougé"
    requirement: "PORT-03"
    verification:
      - kind: unit
        ref: "plugin/consolidator/scripts/tests/test-seed-registres.sh (19 OK / 0 KO)"
        status: pass
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-planning-core.sh (14 OK / 0 KO)"
        status: pass
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-planning-hooks.sh (42 PASS / 0 FAIL)"
        status: pass
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-detect-planning-debt.sh (10 OK / 0 KO)"
        status: pass
      - kind: unit
        ref: "plugin/infrastructure-audit/scripts/tests/test-audit-infra.sh (12 OK / 0 KO)"
        status: pass
      - kind: unit
        ref: "scripts/tests/test-hook-exit-parc.sh (sous-ensemble des 4 scripts, mutations m1/m2)"
        status: pass
    human_judgment: false
  - id: T3
    description: "Suite de parc prouvant le contrat sur les 8 scripts avec garde anti-vert-à-vide, et versions des 4 modules touchés"
    requirement: "PORT-03"
    verification:
      - kind: unit
        ref: "scripts/tests/test-hook-exit-parc.sh (42 OK / 0 KO, 8/8 scripts exercés, mutations m1/m2/m3 toutes rougissantes comme attendu)"
        status: pass
      - kind: unit
        ref: "scripts/check-version-sync.sh — triade VERSION↔module.json et en-tête README des 4 modules : alignés"
        status: pass
    human_judgment: false

duration: n/a (exécution directe, hors sous-agent gsd-executor)
completed: 2026-08-16
status: complete
---

# Phase VFDO-30 Plan 06: Codes de sortie des hooks gouvernance — normalisation côté script, sans câblage de fragment Summary

**8 scripts gouvernance (conductor, consolidator, planning-core, infrastructure-audit) répliquent le
patron `hook_exit()` du plan 30-04 : le silence interne devient 0 sous `--hook` à la frontière du
harness, sans qu'un seul fragment `hooks.json` n'ait bougé. Suite de parc à 42 cas prouvant la
traduction ET le flux, avec garde anti-vert-à-vide.**

## Accomplishments

- **4 scripts qui portaient déjà `--hook`** (`check-agents.sh`, `check-branch-claim.sh`,
  `check-workstream-pointer.sh` — conductor ; `check-registres.sh` — consolidator) gagnent
  `hook_exit()` et traduisent leur(s) code(s) silencieux vers 0 sous `--hook`. `check-agents.sh` a
  déplacé sa traduction du bloc Python embarqué vers le SHELL (où le processus rend la main), sans
  toucher au contrat interne du bloc Python. `check-workstream-pointer.sh` corrige un en-tête devenu
  faux (« --hook ne change AUCUN code de sortie ») et traduit en plus le code 2 pour éviter toute
  collision avec le code 2 réservé au blocage du harness. `check-registres.sh` corrige au passage un
  chemin (`--strict --allow-empty` sur cible vide) qui n'était encore jamais passé par la garde
  `--hook` du tout — un défaut de flux du même type que ceux du plan 30-04.
- **4 scripts sans `--hook`** (`seed-registres.sh` — consolidator ; `check-planning-state.sh`,
  `detect-planning-debt.sh` — planning-core ; `audit-infra.sh` — infrastructure-audit) gagnent la
  parité d'interface (drapeau accepté + mutuelle exclusion `--quiet` → exit 64 quand ce dernier
  existe) et `hook_exit()`, PAS ENCORE câblés dans leur fragment `hooks.json` (migration en forme
  exec de la polarité gouvernance, hors périmètre). `check-planning-state.sh` et
  `detect-planning-debt.sh` n'avaient aucun code « signal » déjà à 0 : leurs 1/2/3 (et 1/3) migrent
  vers 0, et leur seul diagnostic vraiment nominal gagne un `say_diag()` dédié sur stderr pour que
  le cas silencieux ait un stdout réellement vide.
- **`scripts/tests/test-hook-exit-parc.sh`** (nouveau, outillage du dépôt) : 42 cas sur les 8
  scripts, deux flux capturés séparément, 5 entrées bloquantes exclues nommément, garde anti-vert-à-
  vide (plancher 8) prouvée par mutation m3, discrimination m1 (neutralise `--hook`) / m2 (fuite
  stdout) jouée contre chacun des 8 scripts.
- 4 modules bumpés en version mineure (conductor v1.24.0, consolidator v1.10.0, planning-core
  v2.7.0, infrastructure-audit v1.3.0) — VERSION, module.json, en-tête README, CHANGELOG daté.

## Task Commits

1. **Tâche 1 : normaliser les 4 scripts qui portent déjà `--hook`** — `1a75110` (fix)
2. **Tâche 2 : parité d'interface pour les 4 scripts sans `--hook`** — `3826ff5` (fix)
3. **Tâche 3 : suite de parc + versions des 4 modules** — `c46bf72` (test)

_Note : aucun commit de métadonnées séparé — le mandat interdit toute modification de
`.planning/STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md`, la phase VFDO-30 n'étant pas terminée (3 autres
plans en cours en parallèle sur le même arbre, dont deux sur `dev-orchestrator`/`software-architecture`,
hors périmètre de ce plan)._

## Files Created/Modified

- `plugin/conductor/scripts/check-agents.sh` (modifié) — `hook_exit()` au shell, point de traduction du bloc Python déplacé
- `plugin/conductor/scripts/check-branch-claim.sh` (modifié) — `hook_exit()`, codes 3 (SAIN) et 4 (INDÉTERMINÉ) traduits
- `plugin/conductor/scripts/check-workstream-pointer.sh` (modifié) — `hook_exit()`, codes 2 et 3 traduits, en-tête corrigé
- `plugin/conductor/scripts/tests/test-check-workstream-pointer.sh` (modifié) — 3 cas mis à jour pour le nouveau contrat (rc 3→0, rc 2→0 ×2)
- `plugin/consolidator/scripts/check-registres.sh` (modifié) — `hook_exit()`, correctif de flux `--strict --allow-empty`
- `plugin/consolidator/scripts/seed-registres.sh` (modifié) — parité `--hook`, `hook_exit()` (code 1)
- `plugin/planning-core/scripts/check-planning-state.sh` (modifié) — parité `--hook`, `hook_exit()` (codes 1/2/3), `say_diag()`
- `plugin/planning-core/scripts/detect-planning-debt.sh` (modifié) — parité `--hook`, `hook_exit()` (codes 1/3), `say_diag()`
- `plugin/infrastructure-audit/scripts/audit-infra.sh` (modifié) — parité `--hook`, `hook_exit()` (code 3)
- `scripts/tests/test-hook-exit-parc.sh` (créé) — suite de parc, 42 cas, garde anti-vert-à-vide
- `plugin/{conductor,consolidator,planning-core,infrastructure-audit}/{VERSION,module.json,CHANGELOG.md,README.md}` (modifiés) — bumps mineurs

## Decisions Made

- **`check-agents.sh` classé « rien » par l'inventaire 30-04 a quand même reçu `hook_exit()`** —
  parité structurelle exigée par les critères d'acceptation du plan (`grep -c hook_exit ≥ 2` sur les
  4 scripts de la tâche 1), sans changer le comportement observable (déjà 0 systématique sous
  `--hook`).
- **Codes traduits par script déterminés par lecture du chemin de code, pas par un gabarit unique**
  — chaque script a un jeu différent de codes silencieux/signal selon sa propre sémantique interne
  (documenté dans le commentaire de son `hook_exit()`), jamais un renommage global de l'exit 3.
- **`say_diag()` introduit dans 2 scripts** — le seul moyen de satisfaire « stdout strictement vide
  sur cas silencieux » quand le script écrivait TOUT (y compris le cas nominal) sur stdout sans
  distinguer signal et silence.

## Deviations from Plan

- **[Rule 1 — Correctif] `check-registres.sh` : chemin `--strict --allow-empty` jamais passé par la
  garde `--hook`.** Trouvé pendant la tâche 1 en testant systématiquement les combinaisons de
  drapeaux. Corrigé dans le même commit, documenté dans le CHANGELOG.
- **[Rule 1 — Correctif] `check-planning-state.sh`/`detect-planning-debt.sh` : le cas nominal
  écrivait sur stdout.** Découvert en construisant la cible silencieuse du plan de test — sans ce
  correctif, aucun cas silencieux (stdout vide) n'était atteignable sous `--hook` pour ces deux
  scripts, ce qui aurait rendu le critère d'acceptation du plan impossible à satisfaire.
- **[Hors périmètre déclaré, nécessaire à la non-régression] `plugin/conductor/scripts/tests/test-check-workstream-pointer.sh` modifié.** Ce fichier n'est pas dans la liste `Périmètre strict` du
  mandat. 3 de ses cas asseraient l'ANCIEN contrat de `check-workstream-pointer.sh` sous `--hook`
  (rc=3 et rc=2, jamais traduits) — un changement de comportement volontaire de ce plan les aurait
  cassés. Corrigés pour asserter rc=0 (traduit), la propriété de sécurité testée (aucune fuite,
  borne de longueur) restant inchangée et vérifiée. Laisser la suite rouge aurait directement violé
  la section Non-régression du mandat.

**Total deviations:** 3 auto-fixées (2 correctifs de flux, 1 mise à jour de suite préexistante).
**Impact:** aucune régression fonctionnelle ; comportement observable des 8 scripts sous `--hook`
maintenant conforme au contrat documenté dans `docs/HOOKS-CONTRAT-SORTIE.md`.

## Point nécessitant l'attention du manager

- **`scripts/check-version-sync.sh` sort en échec (rc=1), mais PAS à cause de ce plan** : la triade
  VERSION↔module.json et l'en-tête README des 4 modules touchés sont alignés (vérifié
  explicitement). L'échec vient de `README.md`/`README.fr.md` — hors périmètre absolu de ce plan
  (« Interdits ») — dont le compteur « N suites » (55) est déjà en dérive par rapport au réel AVANT
  ce plan (59 suites réelles constatées avant ma première modification, 60 après l'ajout de
  `test-hook-exit-parc.sh`). Dérive préexistante, probablement issue des plans concurrents sur
  `dev-orchestrator`/`software-architecture` qui tournent en parallèle sur ce même arbre — à
  rafraîchir par un mandat habilité à toucher les README racine.

## Requirements Verified

- ✅ PORT-03 — normalisation des codes de sortie des 8 scripts gouvernance restants (D-07),
  couverture complète prouvée par `scripts/tests/test-hook-exit-parc.sh` + les 8 suites dédiées
  préexistantes.
