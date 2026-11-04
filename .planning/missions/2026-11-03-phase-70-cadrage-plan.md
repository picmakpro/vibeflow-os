# Mission 2026-11-03 — Phase 70 : cadrage et planification

**Manager :** vf-dev-manager (`mgr70`), branche `feat/phase-70-finitions-ui` partie de `7370d604`, worktree dédié.
**Périmètre :** cadrage et plans de la Phase 70 « Finitions UI du cockpit » (jalon `vibeflow-v2.0`, compartiment
`fiabilite`). Pas d'exécution : elle partira après le merge de la Phase 69, qui touche les mêmes fichiers.

## Plan de bataille (DAG `MISSION-70.dag.json`)

`scout-code` ∥ `scout-captures` → `cadrage-70` → `plan-70` → `plancheck-70`. Les 5 nœuds sont `done`.
`plan-70` a été rouvert une fois, après les avertissements du premier plan-checker.

## Déroulé

1. **Gestes d'entrée.**
   - Verrou de phase acquis : `--ws=fiabilite --phase=70`, génération `DRIVER.lock.gen.1793730550.9743`.
   - Invariants : SAIN.
   - Flags `workflow._auto_chain_active` et `workflow.auto_advance` lus à `false` par `config-get --ws fiabilite`. Ils n'ont pas été réécrits.
2. **Éclaireurs, en parallèle.**
   - Inventaire du code UI, en lecture seule.
   - Captures Playwright à 390, 768 et 1 440 px, dans les deux thèmes.
   - Leurs constats sont consignés dans `70-CONTEXT.md` § Constats mesurés.
3. **Questions à Samuel.** Six questions, en un seul envoi `SendMessage(main)`. Réponse : « Tout accepter (Recommandé) » (AskUserQuestion, session principale Claude Code, 2026-11-03) → P70-D-01..06.
4. **Ajout au périmètre en cours de mission.** P70-D-16, « Garder en 69, corriger en 70 (Recommandé) » (même canal, même date) : les onglets resserrés par la 69 reviennent aux valeurs de DESIGN.md.
5. **Planification.** vf-coder via `gsd-plan-phase`, recherche sautée. Résultat : 9 plans en 6 vagues (`ded67697`) ; son plan-checker interne n'a trouvé aucun bloquant.
6. **Plan-checker frais, passe 1 (`ded67697`).**
   - Verdict : `issues_found`, 0 bloquant, 2 avertissements.
   - Avertissement 1 : pas de condition d'arrêt à 390 px dans 70-04.
   - Avertissement 2 : risque de chemins machine dans les traces.
   - Les sondes exécutées rougissent comme annoncé : bump, critère 12 px / 2 px sur le code de la 69. Les suites `chrome-fr` et `questions` sont vertes au départ, ce qui fait une base propre.
7. **Correction ciblée.** Le même vf-coder a été repris par SendMessage → `3edc7e51` (+37/-1, 9 plans).
8. **Plan-checker frais, passe 2 (`3edc7e51`).**
   - Verdict : **passed**, 0 bloquant, 0 avertissement.
   - `verify plan-structure --ws fiabilite` : valid sur les 9 plans.
   - `scripts/check-machine-paths.sh` : ✓ 2380 fichiers.
   - Les infos restantes sont reportées dans `70-CONTEXT.md` § À reprendre à la revalidation.

## Couverture

| Exigence | Plans |
|---|---|
| UIFN-01 | 70-04, 70-09 |
| UIFN-02 | 70-04, 70-05 |
| UIFN-03 | 70-04, 70-05 |
| UIFN-04 | 70-03, 70-07 |
| UIFN-05 | 70-08 |
| UIFN-06 | 70-03, 70-05, 70-06 |
| UIFN-07 | 70-01 |
| UIFN-08 | 70-06 |
| UIFN-09 | 70-02, 70-04 |
| UIFN-10 | 70-09 |

## Décompte

Sept mandats émis :
- deux éclaireurs `general-purpose` ;
- un `vf-coder`, repris une fois pour la correction ciblée ;
- deux `gsd-plan-checker` frais.

Un envoi groupé à Samuel. L'estimation d'exécution est relayée verbatim depuis le planificateur : « 45 000 à 90 000 tokens par plan, confiance low ».

## Preuves E6

- Plan-checker passe 2 : `verify plan-structure` (×9, `--ws fiabilite`) → `valid:true`, `errors:[]`, `warnings:[]` ;
  `bash scripts/check-machine-paths.sh` → « ✓ 2380 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine ».
- Plan-checker passe 1 : `test-cockpit-chrome-fr.sh` → 26 PASS / 0 FAIL ; `test-cockpit-questions.sh` → 56 PASS / 0 FAIL
  (base verte avant les témoins à écrire).

## Points ouverts

- **Exécution** : après le merge de la 69, une passe de plan-checker contre le code réel (P70-D-14), puis
  `execute-phase 70` en régime allégé (P70-D-08).
- **Captures** : 70-09 versionne 34 PNG dans le dossier de phase ; c'est à Samuel de confirmer.
- **70-04** s'arrête et remonte si les trois onglets à 13 px ne tiennent pas à 390 ou à 1 024 px.
- **Phase 69** : le jalon affiché à tort (« Trajectoire de equipe-produit » au lieu de `vibeflow-v2.0`) relève de
  CKPT-16 (P70-D-11).
- **STATE.md** : il n'a pas de bloc Phase 70 et n'a pas été touché (consigne « bloc de la 70 seulement ») ; la
  ligne de la 70 est à poser au merge.
