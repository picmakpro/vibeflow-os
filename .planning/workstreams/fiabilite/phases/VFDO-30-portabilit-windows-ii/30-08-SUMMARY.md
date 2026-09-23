---
phase: 30-portabilit-windows-ii
plan: 08
subsystem: ci-preuve-forme-exec
tags: [port-05, adr-071, adr-054]
requires: ["30-06", "30-07"]
provides: [ci-preuve-as-installed, readme-compteur-suites-61]
affects: [.github/workflows/ci.yml, README.md, README.fr.md]
tech-stack:
  added: []
  patterns: ["attendu dérivé de la fermeture installée à chaque exécution (jamais un littéral codé en dur)", "garde anti-vert-à-vide sur 0 entrée VF posée"]
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - README.md
    - README.fr.md
key-decisions:
  - "Deux étapes ajoutées au job « lab frais armé » (job « lab frais » de base et son Gate C non touchés) : « forme exec telle qu'installée » (assertions Python sur settings.json ET settings.local.json posés, command absolu+exécutable sauf la dérogation nommée check-hook-paths.sh, ADR-071 §Décision 2) et « conditions Windows simulées » (test-windows-crlf.sh + test-windows-guards.sh exécutées nommément, repli ADR-054 écrit dans le commentaire de l'étape)."
  - "Cycle rouge → correctif → vert constaté en CI réelle, pas seulement en local : le premier push (commit dcd9eb5, run 31917741411) a échoué sur PORT-05 — l'étape attendait un littéral codé en dur de 6 entrées VF (calculé depuis une install locale DES DEUX modules du périmètre dev), alors que le job lab-frais-arme installe en réalité la seule fermeture résolue de dev-orchestrator (9 modules), qui n'inclut PAS software-architecture. Constat CI : « 5 entrée(s) VF posée(s), attendu 6 » — guard-file-size.sh manquant, comme attendu. Correctif (commit 4edc968) : l'attendu se dérive désormais, À CHAQUE EXÉCUTION, des hooks.json sources des modules de la fermeture réellement résolue (resolve-deps.sh), avec une garde dev-orchestrator ∈ closure et une garde attendu > 0 — les deux mesures (attendu dérivé des sources, constat sur le settings.json posé) restent indépendantes, aucune ne peut se satisfaire elle-même à vide. Repoussé, re-éprouvé : run 31918283177 vert sur les 4 jobs."
  - "Compteur de suites des deux README remis à l'heure : 55 → 61, re-dérivé par la même commande que la CI (find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l), jamais recopié depuis un delta de plans. Une phrase courte ajoutée dans chaque README pour dire ce que les nouvelles suites prouvent (forme exec telle qu'installée, contrat de sortie, résolution Python partagée) — la mention chiffrée seule ne disait rien à un lecteur."
requirements-completed: [PORT-05]
duration: "non tracé"
completed: "2026-08-16"
coverage:
  - deliverable: "La portabilité est prouvée EN CI sur un lab frais : forme exec, chemin absolu, aucun placeholder"
    verification:
      - kind: "ci-run"
        ref: "gh run view 31918283177 (job « Lab frais armé »)"
        status: pass
    human_judgment: true
  - deliverable: "Les deux suites qui simulent les conditions Windows sont vertes et NOMMÉES dans le journal de la CI"
    verification:
      - kind: "ci-run"
        ref: "gh run view 31918283177 — étape « conditions Windows simulées », test-windows-crlf.sh + test-windows-guards.sh nommés"
        status: pass
    human_judgment: false
  - deliverable: "Le gate anti-vert-à-vide échoue quand il ne regarde rien"
    verification:
      - kind: "mutation"
        ref: "bloc extrait verbatim du commit 4edc968, rejoué contre lab vide → FAIL nommé, entrée remise en forme shell → FAIL nommant l'entrée, placeholder résiduel → FAIL"
        status: pass
    human_judgment: false
  - deliverable: "Compteur de suites des deux README exact (61)"
    verification:
      - kind: "command"
        ref: "bash scripts/check-version-sync.sh"
        status: pass
    human_judgment: false
  - deliverable: "Gate de qualité complet vert"
    verification:
      - kind: "ci-run"
        ref: "gh run view 31918283177 — 4 jobs sur 4 en succès (Suites de tests, Lab frais, Gates de qualité mode strict, Lab frais armé)"
        status: pass
    human_judgment: true
---

# Phase 30 Plan 08: Preuve CI « forme exec telle qu'installée » (PORT-05) — Summary

PORT-05 câblé en CI sur le job de lab frais ARMÉ : deux étapes qui prouvent, sur un lab neuf, que
ce que l'install POSE est en forme exec avec un interpréteur absolu, et que les deux suites de
simulation Windows tournent et sont nommées dans le journal. Compteur de suites des deux README
remis à l'heure. **Fait le plus instructif du plan : le premier push a échoué en CI réelle sur
exactement le défaut que la garde anti-vert-à-vide de ce plan visait à empêcher (un attendu qui ne
correspondait pas à ce que le job installe réellement) — corrigé, repoussé, re-éprouvé vert.**

**Durée** : non tracée. **Tâches** : 3 (2 auto + 1 checkpoint humain bloquant).

## Accomplissements

- `.github/workflows/ci.yml` (commit `538f0e3`) : deux étapes ajoutées au job « lab frais armé »
  (le job « lab frais » de base et son Gate C ne sont pas touchés — deux preuves distinctes,
  aucune écrite contre l'autre). Étape « forme exec telle qu'installée » : assertions Python sur
  `settings.json` **et** `settings.local.json` tels que POSÉS par l'install réelle (patron
  as-installed né de la régression #38) — chaque entrée VF portant un champ d'arguments a un
  `command` absolu, existant et exécutable sur le runner, sauf la dérogation nommée
  `check-hook-paths.sh` (nom nu, ADR-071 §Décision 2, addendum humain approuvé le 2026-08-15) ;
  aucun placeholder `{{...}}` résiduel ; aucune construction shell. Garde anti-vert-à-vide sur 0
  entrée VF posée. Étape « conditions Windows simulées » : exécute nommément
  `test-windows-crlf.sh` et `plugin/consolidator/scripts/tests/test-windows-guards.sh`, avec un
  commentaire d'étape qui dit explicitement qu'aucun runner Windows réel n'existe dans ce dépôt et
  que la preuve passe par simulation — repli assumé d'ADR-054.
- `README.md` + `README.fr.md` (commit `ee01800`) : compteur de suites remis de 55 à 61, re-dérivé
  par `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` (même commande que la CI,
  jamais un delta de plans recopié). Phrase courte ajoutée dans chaque fichier disant ce que les
  nouvelles suites de la phase prouvent.
- **Cycle rouge → correctif → vert, constaté en CI réelle** — le premier push (commit `dcd9eb5`,
  run CI `31917741411`) a échoué sur PORT-05 : l'étape « forme exec telle qu'installée » attendait
  un littéral codé en dur (`EXPECT_TOTAL=6`), calculé en local depuis une install des DEUX modules
  du périmètre dev (dev-orchestrator + software-architecture). Le job « lab frais armé » installe
  en réalité la seule fermeture résolue de `dev-orchestrator` (9 modules), qui n'inclut PAS
  `software-architecture` par aucune arête — l'attendu décrivait un univers que ce job ne construit
  jamais. Constat CI exact : « 5 entrée(s) VF posée(s), attendu 6 » — `guard-file-size.sh` (l'unique
  entrée de `software-architecture`) manquant, comme attendu. **Correctif** (commit `4edc968`,
  message : « dériver l'attendu de la forme exec depuis la fermeture installée, pas un littéral ») :
  l'attendu se dérive désormais, À CHAQUE EXÉCUTION, des `hooks.json` sources des modules de la
  fermeture réellement résolue (`resolve-deps.sh` sur `$GITHUB_WORKSPACE`), avec une garde
  `dev-orchestrator ∈ $closure` et une garde `attendu > 0` avant toute comparaison — la source de
  l'attendu (hooks.json du dépôt) et la source du constat (settings.json/settings.local.json posés
  dans le lab armé) restent deux mesures indépendantes, aucune ne peut se satisfaire elle-même à
  vide. Discriminance re-prouvée par mutation sur le bloc extrait verbatim du commit : (a) install
  réelle de la fermeture dev-orchestrator (9 modules, sans software-architecture) → attendu dérivé
  = 5, PASS ; (b) lab vide → FAIL « garde anti-vert-à-vide » ; (c) entrée remise en forme shell →
  FAIL nommant `check-dev-bootstrap.sh` ; (d) placeholder `{{VF_BASH}}` résiduel → FAIL. Poussé,
  re-éprouvé : **run CI `31918283177` vert sur les 4 jobs** (Suites de tests, Lab frais, Gates de
  qualité mode strict, Lab frais armé). Journal cité comme preuve :
  « `== attendu dérivé des hooks.json de la fermeture : 5 entrée(s) VF ==` » et
  « `== forme exec telle qu'installée : 5 entrée(s) VF, command absolu+exécutable (sauf dérogation
  nommée check-hook-paths.sh), aucun placeholder, aucune construction shell ==` », ainsi que
  `test-windows-crlf.sh` et `test-windows-guards.sh` nommés, chacun étiqueté « simulation — pas de
  poste Windows réel », et « `== 61 suite(s) découverte(s) ==` ».

## Deviations from Plan

Aucune déviation de périmètre. Le plan prévoyait explicitement que la tâche 2 fasse une passe
locale complète avant push et que la tâche 3 (checkpoint humain) constate un run CI vert ou
rapporte l'échec sans le contourner — c'est exactement ce qui s'est produit : la passe locale
n'avait pas reproduit le mécanisme de résolution de fermeture que la CI exerce spécifiquement pour
PORT-05 (as-installed testing), d'où le rouge du premier push malgré des suites locales vertes.
Le correctif a été fait dans le plan (commit `4edc968` porte le tag `fix(30-08)`), pas hors de son
périmètre.

## Next Phase Readiness

PORT-05 complété et prouvé en CI réelle (run `31918283177`, 4 jobs sur 4 verts). Les compteurs de
suites des deux README disent la vérité (61). `check-version-sync.sh`, `check-machine-paths.sh` et
`check-state-integrity.sh` verts. `VERSION` racine, `plugin.json` et `marketplace.json` non
touchés — release racine réservée au geste humain.
