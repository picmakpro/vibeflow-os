---
phase: 61-collaboration-deux-humains-divergence-arm-e-preuve-sur-lab-r
plan: 07
subsystem: manuel
tags: [manuel, fr-en, filet-de-divergence, limites, readme, compte-de-suites]
status: complete
requires: [61-02, 61-03, 61-04, 61-05, 61-06]
provides: [manuel FR+EN du filet armé, de sa sortie, de ses limites et du champ Role, compte de suites des README racine juste]
affects: [61-08]
requirements: [COLB-04, COLB-05, COLB-06, COLB-09]
commits: 3
plan_head_before: e303b681ddfe4db3decac96d08f1cecbed5b318b
plan_head_after: d0227f11e78e6332bcc472c4a4393451a6e4a34b
estimate:
  tokens: 60000
actuals:
  tokens: 3100
  tasks: 3
  commits: 3
key-files:
  modified: [manual/fr/05-equipe-agents/sujets-en-parallele.md, manual/en/05-agent-team/parallel-topics.md, manual/fr/01-demarrer/installation.md, manual/en/01-get-started/installation.md, manual/fr/01-demarrer/mettre-a-jour-et-desinstaller.md, manual/en/01-get-started/updating-and-uninstalling.md, manual/fr/02-concepts/qu-est-ce-qu-un-lab.md, manual/en/02-concepts/what-is-a-lab.md, README.md, README.fr.md]
completed: 2026-10-29
---

# Phase 61 Plan 07: le manuel dit le filet, sa sortie et ses limites ; les README comptent juste

Quatre paires de pages FR/EN décrivent le filet armé aux postes product et dev (hooks `post-merge` et `post-rewrite`, cri sans annulation de la fusion, journal `.git/vf-divergence/journal.tsv`, verbe `status`, sortie `VF_DIVERGENCE_HOOK=off`) et les limites mesurées ; les deux README racine passent de 118 à 122 suites.

## Pages et sous-sections
- Sujets en parallèle : phrase périmée « Aucun hook ne le lance » / « No hook runs it in your lab » remplacée (appel manuel gardé pour `solo`) ; deux `###` neufs par langue (« Le filet armé aux postes product et dev », « Ce que le filet ne voit pas » / équivalents anglais), aucune H2 ajoutée (3 H2, 2 H3 de chaque côté).
- Installation : puce « Filet de divergence » / « Divergence safety net » (solo exclu, sortie, armement par `role <poste>`, refus « ARMEMENT REFUSE » sans écrasement, l'install aboutit).
- Mise à jour et désinstallation : rafraîchissement du chemin sans jamais armer ; `uninstall --all` retire le filet, journal gardé, hook tiers jamais modifié.
- Lab : une phrase sur la ligne `**Role**` (optionnelle) dans la puce « La mémoire ».
- Limites écrites telles que mesurées : `reset --hard`, `switch`/`checkout`, `cherry-pick`, `rebase` sans commit réécrit ; fusion sur la forge vue au `git pull` suivant ; `/vf-update` après mise à jour du plugin ; Windows (Git Bash) non mesuré. **COLB-08 n'est pas prétendue** : le manuel ne parle ni de recette jouée ni de preuve sur lab réel.

## Compte de suites (commande et sortie)
`find plugin scripts -type f -path '*/tests/test-*.sh' | awk 'END{print NR}'` : 122 (118 avant + 4 suites de la phase). README.md et README.fr.md : première occurrence « 118 suites » -> « 122 suites », une ligne changée chacun (`ajouts=2 retraits=2` depuis la base de phase) ; VERSION racine et manifestes identiques à la base.

## Gates rejoués
`check-manual.sh` : tous les contrôles passent (C0-C6). `check-version-sync.sh` : rc 0 (le rouge intermédiaire des vagues 1 à 3 est refermé). `check-machine-paths`, `check-gate-touche` (marqueurs 32/32), `check-instruction-budget`, `check-planning-consumers-registered` : rc 0 ; baselines, `manual/toc.yml`, `scripts/hooks`, `.github` inchangés. `check-release-tag.sh` rc 3 (état de tag de la branche, sans lien avec ce plan).

## Deviations from Plan
None - plan executed exactly as written. Tracer : `<verify>` de la tâche 1 vert avant l'expansion. Aucun commit ne touche un gate surveillé : pas de trailer `Gate-Touche`.

## Known Stubs
None.

## Self-Check: PASSED
Dix fichiers du plan modifiés ; commits 8ee11896, 7490e5db, d0227f11 ancêtres de HEAD.
