# Mission 2026-10-06 — Phase 41.4 « Emprunts Pocock »

**Manager** : vf-dev-manager (mode superviser, escalade vivante par SendMessage vers la session principale).
**Branche** : `feat/phase-41-4-emprunts-pocock`, créée depuis `13a52c8f`, le HEAD de la PR #134, docs-only et non
mergée. La PR de la mission vise `main` et reste empilée sur #134.
**Verdict global** : **partiel**. Les 11 plans sont exécutés, POCK-01 à 08 sont cochées et la sonde POCK-04 est
démontrée. La non-régression est verte. La revue du tour 3 rend `gaps_found` avec 4 majeurs auto-fix. Le budget de
3 tours est épuisé et je me suis arrêté sur consigne de Samuel : pas de quatrième tour.

## Plan de bataille (DAG `.planning/workstreams/fiabilite/MISSION-414.dag.json`)

1. `discuss-414` (manager, Pattern F).
2. `plan-414` (vf-coder → gsd-plan-phase).
3. `exec-w1` → `exec-w2` → `exec-w3` → `exec-w4`, puis `sonde-pock04` (manager).
4. `revue-w1` / `revue-414` (vf-reviewer, deux axes), avec les corrections `corr-a`, `corr-b` et `corr-c`.
5. `nonreg-414` (manager), `docs` (audit read-only), `pr-414`.

Pas d'audit sécurité : la phase ne touche ni secret ni donnée.

## Arbitrages

Tous sont des arbitrages Samuel, AskUserQuestion session principale, 2026-10-06, relayés par SendMessage.
- **P414-D-01 à D-11** : 11 questions en 3 zones, toutes en option (a).
- **D-17 et D-18** : aucun skill user-invoked aujourd'hui ; critère 7 reformulé.
- **D-19** : critère 8 et POCK-08, « signalé » au lieu de « refusé ».
- **D-20** : seuil d'un axe = aucun bloquant ni majeur.
- **D-21** : deux fixtures de sonde. P414-D-07 est étendue, pas contredite.
- **D-22** : sans PLAN, l'axe Spec rend `skipped`.

Décisions du manager : P414-D-12 à D-16, la mise en conformité de D-10, et l'interprétation de D-22 (un axe
`skipped` sort de la conjonction ; aucun axe jugé → `blocked`). **Cette interprétation est à ratifier.**

## Décompte (budget épuisé, Pattern E §6)

- **Tours de correction** : 3 sur 3 (A+B, puis C).
- **Tours de revue** : 3, tous en régime plein.
  - Tour 1 : 10 majeurs.
  - Tour 2 : 3 majeurs nouveaux, les 8 du tour 1 corrigés.
  - Tour 3 : 4 majeurs.
- **Sondes POCK-04** : 3 tours, conformes au tour 3.
- **Workers dispatchés** : 22 Task émises par le manager.
  - 2 éclaireurs.
  - 8 vf-coder : plan, vagues 1 à 4, corrections A, B et C.
  - 4 vf-reviewer.
  - 4 sondes.
  - Le reste dans les tours ci-dessus.
- Les briques de profondeur 2 sont consignées par chaque worker au registre `DRIVER.lock.children.jsonl`.

**Findings restés non résolus** (revue tour 3, rapports `scratchpad/revue-t3/REVIEW-{standards,spec}-t3.md`) :
1. **M3-01** `check-mission-exit.sh:325,328`. Sous mawk 1.3.4, `sub(/^ ? ? ?/)` n'ôte qu'un espace : une fence
   indentée de 2 ou 3 espaces masque la section merge-danger. Résultat : faux MANQUE sous Linux, sans danger
   côté sécurité. Correctif identifié (`strip3`).
2. **M3-02** `test-check-skills.sh:1459-1476`, T38d. Le test du lien symbolique `openai.yaml` ne peut pas rougir, car
   la fixture est refusée pour une autre raison. Le code est correct, la preuve est vide.
3. **M3-03** CHANGELOG de dev-orchestrator (l.17-21, 31) et de design-orchestrator (l.7). Ils sont périmés après la
   correction C : ni D-20 ni D-22 n'y figurent, et les comptes de cas ou de mutants sont faux.
4. **M3-04** E3 : les gardes E18 (Rayon hors section) et E15 (`Porte` invalide + valide) n'ont pas de fixture, et
   leurs mutants survivent.
5. **Mineurs auto-fix** listés au rapport t3 : chiffres périmés dans REQUIREMENTS, CHANGELOG conductor et
   SUMMARY 10 ; règle de conjonction non mise à jour dans `mission-flow.md:307`, `REFERENCE.md:15` et la
   description de vf-reviewer ; paraphrases de D-22 ; « revue PASS » dans `team-kernel.md` ; contrat E3 muet sur
   les blocs ignorés ; message du SHA ; `od -v` dans `scripts/check-gate-touche.sh`.

Aucune proposition de next step n'accompagne ce décompte (Pattern E §6). Le next step de la feuille de route est
donné plus bas, séparément.

## Preuves E6

- **Sonde POCK-04** : `41.4-SONDE-POCK04.md`, HEAD `c22025e2`, blocs typés verbatim.
  - Sonde 1 : Standards passed / Spec gaps_found.
  - Sonde 2 : Spec passed / Standards gaps_found.
- **Rejeu du job CI `gates`** (`rejouer-ci.sh --job gates`, clone de `c22025e2`) : 18 étapes sur 18 à rc=0, dont
  l'étape neuve check-skills. 3 étapes sautées par construction : checkout, G-3 réel, release-tag main-only.
- **Rejeu du job CI `tests`** (même outil, même HEAD) : 98 suites, 92 PASS, 6 FAIL d'environnement.
  - Causes des 6 échecs : PyYAML masqué par le HOME jetable, moteur gsd-core non installé (étape `npx` refusée).
  - Aucun fichier testé par ces 6 suites n'est touché par la phase (`git diff --stat 88553972 c22025e2` vide).
  - Rejouées dans l'environnement réel du poste, elles rendent toutes rc=0 :
    - description-fidelity 56/0 ;
    - planning-not-inflight 34/0 ;
    - dag 161/0 ;
    - split-planning 69/0 ;
    - gsd-config 37/0 ;
    - quick-validate 5/0.
- **Suites de la phase** (rapportées par les workers et recoupées par la revue t3) :
  - test-check-skills 125/0 ;
  - test-check-ajout-retrait 83/0 (29 mutants) ;
  - test-check-mission-exit 122/0 ;
  - test-consolidator 90/0 ;
  - test-dev-orchestrator 279/0.
- **Gates de branche** : check-gate-touche DECLARE, check-baseline-arbitrage CONFORME, check-version-sync rc 0.

## Ce qui reste ouvert, hors décompte

- La PR touche `.github/workflows/ci.yml`. Elle est BLOCKED jusqu'à la revue de @picmakpro (rulesets), sans
  contournement.
- Le manifeste `check-agents-manifest.json` périme le 2026-10-23 : la CI rougira après cette date. Hors périmètre.
- `main` a avancé (PR #131) depuis la base de #134. Un rebase sera peut-être à faire au merge, avec un conflit
  possible sur le ROADMAP du compartiment `fiabilite`.
- Dettes consignées au BACKLOG : équivalent Codex des skills de type 1 ; tension du routage « ship ».

## Next step (feuille de route)

Un tour de correction ciblée des 4 majeurs et des mineurs auto-fix du rapport t3, sur feu vert de Samuel, puis le
merge de #134 et de cette PR. Ensuite la clôture du jalon `fiabilite-v1.0`.

## Tour 4 (P414-D-23 — arbitrage Samuel, AskUserQuestion session principale, 2026-10-06)

- **Rebase** sur `origin/main` (`ee625735`, PR #131) : 61 commits rejoués. Deux conflits ont été résolus en
  conservant les deux inscriptions : la ligne « Depends on » du ROADMAP `fiabilite`, et le paragraphe 41.2 de
  STATE, préfixé « Antérieur ». L'équivalence est prouvée par `cmp` et `comm`. Le tour 4 est commité au HEAD
  `f5fcfcad`, poussé avec lease.
- **Correction D** : M3-01 à M3-04 fermés.
  - E3 rend le même verdict sous BWK, mawk 1.3.4 et 20240123, busybox et gawk (mesuré par la revue).
  - T38d rougit désormais.
  - CHANGELOG mis à jour sur D-20 et D-22.
  - Gardes E15 et E18 épinglées.
  - Mineurs T3-03 à T3-07 et `od -v` traités.
- **Témoins** :
  - job `gates` rejoué : 18 étapes sur 18 à rc=0 ;
  - suites de la phase : check-skills 126/0, check-ajout-retrait 83/0, check-mission-exit 135/0, consolidator 90/0,
    dev-orchestrator rc=0, check-gate-touche 34/0, quick-validate 5/0, scaffold-docs 26/0.
- **Revue tour 4** : Standards `passed` (6 mineurs), Spec `gaps_found` à cause d'un majeur.
  - **M4-01** : `plugin/dev-orchestrator/CHANGELOG.md:23-24` et `ROADMAP.md:1642` (fiabilite) disent encore que la
    sonde POCK-04 « reste à jouer », alors qu'elle a été jouée (`41.4-SONDE-POCK04.md`).
  - Le correctif tient en trois lignes de texte.
  - Les mineurs m4-02 à m4-07 sont dans `scratchpad/revue-t4/`.
- **Décompte final** : 4 tours de correction sur 4, 5 revues complètes, 3 tours de sonde. La PR reste en brouillon,
  conformément au mandat : sortie seulement si les deux axes passent.
