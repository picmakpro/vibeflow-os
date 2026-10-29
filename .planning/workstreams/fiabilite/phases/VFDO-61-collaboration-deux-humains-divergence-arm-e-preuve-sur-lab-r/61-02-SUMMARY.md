---
phase: 61-collaboration-deux-humains-divergence-arm-e-preuve-sur-lab-r
plan: 02
subsystem: consolidator
tags: [registres, role, gabarits, optionnel-en-lecture, mutation]
status: complete
requires: []
provides: [ligne **Role** des gabarits DEC/LRN/BLK (source et copies), suite test-registres-role.sh]
affects: [61-06, 61-07, 61-08]
requirements: [COLB-06, COLB-09]
commits: 2
plan_head_before: ac01d5536ecb5cdc9c5d369787486bd43cc30698
plan_head_after: 165ee0e12ff0d0ceedbd93d312ce3d5ca91cc62e
actuals:
  tokens: 8500
  tasks: 2
  commits: 2
key-files:
  created: [plugin/consolidator/scripts/tests/test-registres-role.sh]
  modified: [plugin/reference/content/methodology/templates/memory/decisions-template.md, plugin/reference/content/methodology/templates/memory/learnings-template.md, plugin/reference/content/methodology/templates/memory/blockers-template.md, plugin/consolidator/references/templates-memoire/decisions-template.md, plugin/consolidator/references/templates-memoire/learnings-template.md, plugin/consolidator/references/templates-memoire/blockers-template.md]
completed: 2026-10-29
---

# Phase 61 Plan 02: champ Role des registres, optionnel en lecture et prouvé

Les entrées DEC, LRN et BLK portent une ligne `**Role**` (poste de l'auteur lu par `vf-role.sh get`), et six consommateurs rendent la même chose avec et sans elle ; aucun parseur modifié.

## Ligne posée (identique à l'octet dans les six gabarits, après le dernier champ du squelette)
`**Role** : [poste de l'auteur : sortie de vf-role.sh get — solo, product ou dev ; ligne omise si le lecteur rend 1, 5 ou 64, jamais solo par défaut]`

## Commits (règle SYNC : source puis copies)
5b79e196 sources (`reference`) + suite tracer · 165ee0e1 copies (`consolidator`) + volet consommateurs et témoins. Chaque gabarit : 1 ligne ajoutée, 0 retirée (`--numstat` depuis la base de phase) ; `merge-base --is-ancestor` source avant copie ; parseurs intacts.

## Suite `test-registres-role.sh` (30 ok / 0 ko)
RRO-TPL (source et copies : une seule ligne, bien placée, mention de `vf-role.sh get` et « jamais solo », bandeau SYNC conservé), RRO-VALEUR (rc 0 product ; rc 1 et rc 5 sortie vide et aucune ligne, jamais solo ; rc 64), RRO-CHECK, RRO-REINDEX (audit, dry-run avec Resume non vide, index après `--apply`, trois registres), RRO-ARCHIVE, RRO-DUP, RRO-PROMO, RRO-SEED, RRO-COMPARATEUR-TEMOIN.
Mutants prouvés rouges, original resté vert : RRO-TEMOIN-REINDEX (fenêtre du Resume 40 → 2, exigé par le plan), plus RRO-TEMOIN-CHECK (IDs dupliqués lus sur la ligne Role), RRO-TEMOIN-ARCHIVE (Statut relu sur Role), RRO-TEMOIN-PROMO (Encode dans relu sur Role). Sans mutant : RRO-DUP et RRO-SEED (le témoin non vide de chacun, collision et titres proches, ligne dans le squelette, est exigé).

## Vérifications rejouées
`test-registres-role.sh` vert sous bash, `/bin/bash` 3.2 et mawk 1.3.4 de la CI (3 s). `test-consolidator.sh` 102/0 (13 s), `test-check-registres.sh` 15/0, `test-seed-registres.sh` 19/0, `test-decay.sh` 27/0. `check-machine-paths`, `check-gate-touche`, `check-instruction-budget`, `check-python-isolation --min-sites 40`, `check-planning-consumers-registered` rc 0 ; baselines, `scripts/hooks`, `.github` inchangés.

## Deviations from Plan
None - plan executed exactly as written. Ajout de trois mutants au-delà du témoin demandé (sondes réutilisables par consommateur).

## Limite constatée (non corrigée, aucun parseur modifié)
`detect-promotions.sh` lit les 500 premiers caractères d'une entrée pour repérer un mot opérationnel : la ligne Role (~19 caractères) décale cette fenêtre. Mesuré hors suite : un mot-clé aux caractères 481-500 donne un candidat sans le champ, aucun avec. Heuristique grossière au tri final humain, effet marginal, à connaître.

## Rouge intermédiaire attendu
`check-version-sync.sh` : compte de suites 118 ≠ 120 (README et README.fr), repris en 61-07 ; bumps de consolidator et reference en 61-06.

## Known Stubs
None.

## Self-Check: PASSED
Fichiers présents ; commits 5b79e196 et 165ee0e1 ancêtres de HEAD.
