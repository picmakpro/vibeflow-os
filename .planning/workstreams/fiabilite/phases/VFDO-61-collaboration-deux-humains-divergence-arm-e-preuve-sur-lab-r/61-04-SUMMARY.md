---
phase: 61-collaboration-deux-humains-divergence-arm-e-preuve-sur-lab-r
plan: 04
subsystem: installeur
tags: [divergence, installeur, vibeflow-update, VF_DIVERGENCE_HOOK, mutation]
status: complete
requires: [61-01]
provides: [VF_DIVERGENCE_HOOK, divergence_hook_apply complète, divergence_hook_disarm_scoped, divergence_hook_refresh_scoped, suite test-vibeflow-update-divergence.sh]
affects: [61-05, 61-06, 61-07]
requirements: [COLB-01, COLB-03, COLB-05, COLB-09]
commits: 3
plan_head_before: 99ffcd684568b5d08d8a69b76a3d8a38e57655fe
plan_head_after: 1f25c08642f416c867f585ab1309ac1710bbfb02
actuals:
  tokens: 12900
  tasks: 3
  commits: 3
key-files:
  created: [plugin/_internal/tests/test-vibeflow-update-divergence.sh]
  modified: [plugin/_internal/vibeflow-update.sh]
completed: 2026-10-29
---

# Phase 61 Plan 04: l'installeur porte tout le cycle de vie du filet

L'installeur arme aux postes product/dev, retire au poste solo, à `uninstall --all` et sous `VF_DIVERGENCE_HOOK=off`, re-pointe le hook vers le cache courant à `update --all` sans jamais armer un clone non armé ; 17 cas et 10 mutants tués.

## Engine (`plugin/_internal/vibeflow-update.sh`)
`divergence_off`, `divergence_hook_present`, `divergence_hook_plan <~|-> <ours>`, `divergence_hook_disarm`, `divergence_hook_apply <poste>` (appelée en dernière ligne de `role_apply`, product/dev arment ou retirent sous off, solo retire), `divergence_hook_scope_ok`, `divergence_hook_disarm_scoped` (fin de `uninstall --all`), `divergence_hook_refresh_scoped` (fin de `update --all`, `arm --refresh`). Validation de `VF_DIVERGENCE_HOOK` dans le bloc de validation des verbes : refus code 1 à `install` avec poste et à `role`, ignorée avec une ligne de log à `update --all` et `uninstall` (revalidation 2026-10-29). Script cherché dans le cache seul (`find_divergence_hook`, 0 repli). En-tête d'usage : paragraphe « Filet de divergence (Phase 61) ».

## Lignes stderr telles qu'écrites
`[divergence] filet armé` · `filet retiré` · `chemin du filet rafraîchi` · `ARMEMENT REFUSE (code 1)` · `armement NON VERIFIABLE (code 2)` · `pas de dépôt git : filet non armé` · `NON VERIFIABLE : vf-divergence-hook.sh absent du cache du plugin — filet non armé` (retrait/rafraîchissement : « hook VibeFlow laissé en place… » / « chemin du filet non rafraîchi », dites seulement si un hook nôtre est présent) · `retrait INCOMPLET (code 1)` · `rafraîchissement REFUSE (code 1)` · `VF_DIVERGENCE_HOOK invalide (attendu on ou off) : valeur ignorée…`. Dry-run : `[plan] ~ <cible>  (filet de divergence : hook git du clone, hors de l'arbre versionné)` ; `[plan] - <cible>  (filet de divergence : hook VibeFlow retiré)`.

## Suite `test-vibeflow-update-divergence.sh` (27 ok / 0 ko, 19 s ; bash, `/bin/bash` 3.2.57, mawk de la CI)
17 cas : VUD-TRACE, ROLE-SOLO (journal intact par cksum), ROLE-DEV, PRODUCT, LOCAL, SOLO (dossier de hooks = `git init` témoin), USER, TARGET, NOGIT, TIERS (hook tiers intact, engine rc 0), DRY, IDEMPOTENT, OPTOUT, OPTOUT-INV (valeur absente de stdout/stderr), UNINSTALL, UPDATE-REFRESH (cache-a supprimé, le hook crie encore), CACHE-SEUL (piège non déclenché).
10 mutants tués (attendu/obtenu imprimés) : 1 appel retiré (ours 2→0), 2 armement au solo (0→2), 3 retrait solo neutralisé (0→2), 4 retrait uninstall neutralisé (0→2), 5 off ignoré (0→2), 6 rafraîchissement neutralisé (a0 b2→a2 b0), 7 repli sur la cible (piege non→oui), 8 refus non relayé (oui→non), 9 dry-run qui arme (hooks0 plan2→hooks2 plan0), 10 valeur invalide acceptée (rc1 hooks0→rc0 hooks2).

## Non-régression (une à une, borne 600 s)
`test-vibeflow-update-role` rc=0 50 s · `test-roles-e2e` rc=0 34 s · `test-manifest` rc=0 18 s · `test-vibeflow-update` rc=0 152 s. `check-planning-consumers-registered`, `check-machine-paths`, `check-python-isolation --min-sites 40`, `check-instruction-budget`, `check-gate-touche` (marqueurs 32/32) : rc 0, baselines intactes.

## Deviations from Plan
None - plan executed exactly as written. Ajouts de forme : lignes `retrait INCOMPLET`, `rafraîchissement REFUSE` et `chemin du filet rafraîchi` (non listées au tableau du plan) ; en refus du retrait/rafraîchissement faute de script, la ligne `NON VERIFIABLE` n'est dite que si un hook nôtre est présent (un lab jamais armé ne reçoit aucune ligne).

## Rouge intermédiaire attendu
`check-version-sync.sh` : compte de suites README (118 ≠ 122), repris en 61-07. Ni bump ni changelog ici (61-06).

## Known Stubs
None.

## Self-Check: PASSED
Fichiers présents ; commits 4922bb5e, a2d44adf, 1f25c086 ancêtres de HEAD.
