---
phase: 61-collaboration-deux-humains-divergence-arm-e-preuve-sur-lab-r
plan: 03
subsystem: conductor
tags: [divergence, git-hook, post-rewrite, core-hooksPath, journal, mutation]
status: complete
requires: [61-01]
provides: [post-rewrite, refus d'armement (hooksPath, tiers, arbre, racine), arme-a-la-main, status, garde d'execution, journal blinde, suite test-vf-divergence-hook.sh]
affects: [61-04, 61-05, 61-06, 61-07]
requirements: [COLB-02, COLB-03, COLB-04, COLB-09]
commits: 3
plan_head_before: 47a1efc9e92268ef3cabc7433106ad06c487186c
plan_head_after: 621408b21a633f0f0409df5183a70bcf54c83dc9
actuals:
  tokens: 7100
  tasks: 3
  commits: 3
key-files:
  created: [plugin/conductor/scripts/tests/test-vf-divergence-hook.sh]
  modified: [plugin/conductor/scripts/vf-divergence-hook.sh]
completed: 2026-10-29
---

# Phase 61 Plan 03: le filet refuse tout ce qui appartient à l'humain et n'exécute jamais l'arbre

`post-rewrite` double `post-merge` (un vrai `git pull --rebase` crie et journalise), `arm` refuse avant d'écrire, `run` refuse un script sous l'arbre inspecté, le journal n'ouvre ni lien, ni FIFO, ni dossier ; 37 cas dont 12 mutants tués.

## Étiquettes telles qu'écrites
`arm` code 1 : `REFUS lab-hors-racine-git`, `REFUS core.hooksPath`, `REFUS executable-dans-l-arbre`, `REFUS hook-tiers:<nom>`, `REFUS ligne-perimee:<nom>` (suivis de `LIGNE A AJOUTER A LA MAIN (<nom>)` et `SORTIE : VF_DIVERGENCE_HOOK=off`) ; code 2 : `NON VERIFIABLE chemin-non-sur | hooks-irresolu | ecriture-echouee` ; `ARME-A-LA-MAIN` code 0. `disarm` : code 1 + `LIGNE A RETIRER A LA MAIN (<nom>)`. `status` (stdout) : `HOOK <nom> ARME|ARME-A-LA-MAIN|TIERS|ABSENT`, `JOURNAL <chemin> lignes=<n>`, `BILAN verbe=status code=<n>`. `run` : raison `executable-dans-l-arbre` / `code-<n>` / `introuvable` ; `JOURNAL NON ECRIT : lien|fifo|non-regulier|dossier-lien`.

## Matrice des hooks (recopiée de l'en-tête, git 2.50.1)
pull ff, pull --ff-only, pull --no-rebase, merge, pull --rebase sans commit local : post-merge 0 · merge --squash : post-merge 1 · pull --rebase avec commit local : post-rewrite rebase (jamais post-merge) · commit --amend : post-rewrite amend (silence) · reset --hard, switch/checkout, cherry-pick, rebase sans commit réécrit : aucun. Une fusion faite sur la forge est vue au `git pull` local suivant.

## Suite (37 ok / 0 ko, 32 s)
VDH-TRACE, REWRITE, REWRITE-AMEND, JOURNAL, ARM-TIERS, ARM-MAIN, ARM-HOOKSPATH (local et global), ARM-ARBRE, ARM-RACINE, ARM-QUOTE, ARM-IDEMPOTENT, ARM-WORKTREE (journal commun), DISARM, DISARM-TIERS, STATUS, NOGIT, USAGE, RUN-ARBRE (piège non déclenché), RUN-SILENCE, RUN-NV (+ codes 0/1/2 en run direct), INTROUVABLE (+ repli sur journal lien), JOURNAL-LIEN (+ FIFO bornée, dossier, dossier lien), CODES (run {0,1,2,64}, arm {0,1,2,3,64}).
Mutants tués, chacun avec message obtenu imprimé : MUT-1 cri muet, 2 journal neutralisé, 3 code 2 avalé, 4 refus tiers retiré, 5 marqueur de `disarm` retiré, 6 refus hooksPath retiré, 7 refus arbre à l'armement retiré, 8 garde d'exécution retirée (piège déclenché), 9 `rebase` ignoré, 10 `amend` non filtré, 11 contrôle de chemin retiré, 12 lien du journal suivi.

## Vérifications rejouées
Suite neuve verte sous bash, `/bin/bash` 3.2 et mawk 1.3.4 de la CI. `test-vibeflow-update-role.sh` 54/0, `test-divergence-deux-clones.sh` 6/0, `test-check-divergence.sh` 22/0. `check-planning-consumers-registered`, `check-python-isolation --min-sites 40`, `check-machine-paths`, `check-instruction-budget` : rc 0 (baselines intactes). G-2 : rc 0 (`marqueurs: lus=32 conformes=32`, DECLARE). Zéro `eval`, zéro écriture de configuration git. Tracer : bouclé en auto, `<verify>` rejoué vert avant l'expansion.

## Deviations from Plan
None - plan executed exactly as written. Précisions de forme : le refus `executable-dans-l-arbre` n'imprime pas de `LIGNE A AJOUTER A LA MAIN` (elle pointerait un script de l'arbre) ; `arm --refresh` avec `core.hooksPath` configuré rend 0 sans écrire ; `GIT_CONFIG_NOSYSTEM` n'est plus exporté par `arm`/`disarm`/`status` (un `core.hooksPath` système doit être vu) ; le stderr de `check-divergence.sh` reste relayé tel quel y compris sa ligne « conforme » (comme `scripts/hooks/post-merge`) : « silence » veut dire aucune sortie `[vf-divergence]` ni ligne de journal.

## Rouge intermédiaire attendu
`check-version-sync.sh` (compte de suites README), repris en 61-07 ; bumps en 61-06.

## Known Stubs
None.

## Self-Check: PASSED
Fichiers présents ; commits 76373ca9, d37b592c, 621408b2 ancêtres de HEAD.
