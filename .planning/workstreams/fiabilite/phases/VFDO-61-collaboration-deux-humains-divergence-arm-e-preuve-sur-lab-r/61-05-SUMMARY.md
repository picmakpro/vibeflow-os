---
phase: 61-collaboration-deux-humains-divergence-arm-e-preuve-sur-lab-r
plan: 05
subsystem: preuve
tags: [divergence, deux-clones, temoins-rouges, recette, mutation]
status: complete
requires: [61-01, 61-03, 61-04]
provides: [suite test-divergence-deux-clones.sh complete (16 cas), sonde_cri, 61-RECETTE-LAB-REEL.md]
affects: [61-06, 61-07, 61-08]
requirements: [COLB-03, COLB-04, COLB-07, COLB-08]
commits: 3
plan_head_before: 7ce8db3e8fd8338ba406dafb7d80d821e42de595
plan_head_after: 2656b268b7bb7637dc9943a120051050fe603d36
estimate:
  tokens: 100000
actuals:
  tokens: 10900
  tasks: 3
  commits: 3
key-files:
  created: [.planning/workstreams/fiabilite/phases/VFDO-61-collaboration-deux-humains-divergence-arm-e-preuve-sur-lab-r/61-RECETTE-LAB-REEL.md]
  modified: [plugin/_internal/tests/test-divergence-deux-clones.sh]
completed: 2026-10-29
---

# Phase 61 Plan 05: preuve de mécanisme complète et recette du lab réel

La preuve à deux clones couvre les trois façons de recevoir le travail de l'autre humain, le silence, le worktree lié, la branche piégée et trois témoins qui la font rougir ; la recette du lab réel est livrée et son relevé est joué tel quel par la suite. **COLB-08 reste décochée** : la recette n'a pas été jouée, aucun compte rendu n'existe.

## Suite `test-divergence-deux-clones.sh` : 16 cas (6 de 61-01, 10 de ce plan), 16 ok / 0 ko, 20 s
- `sonde_cri` : cri sur stderr ET exactement une ligne de journal `DIVERGENCE` portant le HEAD du clone ; `SONDE_WHY` dit la condition manquante. `monde` : origine fraîche + deux clones armés par l'install (aucun appel direct à `arm`).
- D2C-FF (avance rapide, `post-merge`, sur A chaîné à D2C-TRACE), D2C-REBASE (`pull --rebase` avec commit local, `post-rewrite`, champ 5 = HEAD après rebase), D2C-CONFORME (sortie du contrôle relayée, aucune ligne `[vf-divergence]`, aucun journal), D2C-WORKTREE (journal du dossier commun, HEAD du worktree lié, checkout principal conforme), D2C-PIEGE (cinq scripts piégés poussés, aucun déclenché ; témoin positif : chacun dépose sa marque à la main).
- Témoins : D2C-TEMOIN-DESARME (`role solo` par l'engine), D2C-TEMOIN-CD-MUTE (S2 aveugle dans une copie du cache), D2C-TEMOIN-RUNNER-MUTE (écriture du journal neutralisée : cri présent, journal muet). Chacun : copie différente par `cmp -s`, valide par `bash -n`, attendu/obtenu imprimés, sonde verte sur l'original.
- D2C-RELEVE / D2C-RELEVE-TEMOIN : le script est extrait de la recette (marqueurs `releve:debut/fin`) et joué tel quel sur B (fusion), A (avance rapide), rb-1 (fin de rebase), cf-2 (conforme). Rouge si une ligne de journal manque, porte un autre HEAD, ou si le journal est absent ; code 2 sur cache introuvable.

## Mutants prouvés rouges (copie de `plugin/`, original intact ; suite jouée sur le mutant)
sonde aveugle (4 ko : trois témoins) · engine n'arme pas (31 ko) · `post-rewrite` ignore `rebase` (4 ko, D2C-REBASE) · exécutable résolu depuis l'arbre sans garde (21 ko) et variante qui exécute le piège (2 ko, D2C-PIEGE : piège déclenché) · répertoire inspecté = parent du dossier commun (2 ko, D2C-WORKTREE) · journal aussi sur conforme (2 ko, D2C-CONFORME). Relevé (copie de la recette) : appariement toujours vrai (1 ko), verdict divergent aboli (5 ko), worktrees avec hooks (1 ko), appariement sans HEAD (1 ko, d'où la variante « autre HEAD » du témoin).

## Vérifications rejouées
Suite verte sous bash, `/bin/bash` 3.2.57 et mawk 1.3.4 de la CI. `check-machine-paths` (recette comprise), `check-gate-touche` (32/32), `check-python-isolation --min-sites 40`, `check-planning-consumers-registered`, `check-instruction-budget` : rc 0, baselines intactes. Recette : six rubriques uniques, renvois D2C-RELEVE, COLB-08, P61-B-01, SUBIE-EN-SILENCE ; `[x] COLB-08` : 0.

## Deviations from Plan
None - plan executed exactly as written. Choix de forme : D2C-REBASE joue sur un monde frais et conforme (rb-1, rb-2) plutôt que sur A/B, pour que le seul désaccord soit 03-p/03-q ; D2C-FF reste chaîné sur A/B comme prévu. Tracer : `<verify>` rejoué vert avant l'expansion (mode auto).

## Rouge intermédiaire attendu
`check-version-sync.sh` : compte de suites README, repris en 61-07 ; bumps en 61-06.

## Known Stubs
None. Les cellules vides du gabarit de compte rendu sont voulues : la recette n'a pas été jouée.

## Self-Check: PASSED
Fichiers présents ; commits 817b284a, d9b62c4e, 2656b268 ancêtres de HEAD.
