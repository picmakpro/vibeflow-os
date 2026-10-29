---
phase: 60-gate-architecture-avant-d-coupage-et-validation-des-phases-p
plan: 09
subsystem: ledger
tags: [porte-de-phase, rejeu-ci, ledger-a-la-main, arret-avant-pr]
requires: [60-01, 60-02, 60-03, 60-04, 60-05, 60-06, 60-07, 60-08]
key-files:
  modified: [.planning/workstreams/fiabilite/REQUIREMENTS.md, .planning/workstreams/fiabilite/ROADMAP.md, .planning/workstreams/fiabilite/STATE.md]
status: complete
commits: 2
plan_head_before: ee2911921ebd5848444e782c5eca2977e66a7a60
plan_head_after: 4c2344dc398961f97b3c9d4b3e0edef7ea6c4ef2
actuals: {tokens: 12000, tasks: 3, commits: 2}
---

# Phase 60 Plan 09: porte de phase rejouée et ledger Summary

Le job `gates` est rejoué depuis `ci.yml`, quatorze suites une à une, le ledger est mis à jour à la main sur preuve : neuf ARCG cochées, ARCG-01 et ARCG-09 laissées partielles, arrêt avant PR. `plan_head_after` est le commit du ledger ; le commit de ce SUMMARY est la pointe de la branche.

## Porte de phase
- Étapes extraites par `replay-ci-jobs.sh --job gates --list` (23 lignes) ; rejeu `perl -e 'alarm 1800; exec @ARGV' bash <outil> --job gates` : **rc 0, 23 s, `20 rejouee(s), 3 sautee(s), 0 en echec`**. Étapes 2 à 21 rc 0 : check-agents (3 formes), check-skills, check-blueprints, check-version-sync, check-state-integrity, check-capability-activation, check-machine-paths, check-python-isolation, check-instruction-budget, gates workstream-aware, check-divergence, check-planning-consumers-registered, G-1, G-2, SOBR-05, G-4, check-manual, G-3 par fixture. Sautées, jamais comptées vertes : l'étape d'action (checkout) et, conditionnées à `main`, G-3 en mesure réelle et check-release-tag.
- `check-instruction-budget.sh` rc 0, `37 fichier(s), 0 depassement(s)`, BOOTSTRAP `ligne 2610` inchangée.
- Gardes : G-2 rc 0 (15/15 marqueurs `Gate-Touche` conformes, 5 chemins de surface) ; `check-ajout-retrait --strict` rc 0 (`AJOUT-COUVERT` pour `check-phase-validation.sh` et `check-architecture.sh`) ; G-1 rc 0 `CONFORME` ; consommateurs rc 0 ; `check-version-sync.sh` rc 0 (v2.72.0, 18 modules, 116 suites) ; `check-manual.sh` rc 0 ; `check-state-integrity.sh` rc 0 après l'édition de STATE.
- **Base des gardes** : `merge-base HEAD origin/main` = `cbe97fb1`, base de phase PB = `2649ccd4`, 60 commits jugés en plus par les gardes, 0 commit de PB absent de leur base. G-1, G-2 et SOBR-05 ont donc jugé aussi des commits antérieurs à la phase (Phase 59 et sa release, `origin/main` périmé) : leurs verts portent sur cette plage-là, pas sur la seule plage PB..HEAD.
- **Suites une à une** (commande `perl -e 'alarm 600; exec @ARGV' bash <suite>`, rc 0 chacune sauf mention) : phase-validation 46 ok / 0 ko, 6 s ; architecture 34 / 0, 4 s ; vf-validation 35 / 0, 8 s ; product-team-bundle 104 / 0, 9 s ; check-prd 13350 / 0, 127 s ; dev-orchestrator 398 / 0, 43 s en rejeu isolé ; consumers-registered 7 / 0, 1 s ; instruction-budget 69 / 0, 7 s ; check-agents 200 / 0, 14 s ; check-skills 126 / 0, 17 s ; planning-core 14 / 0, 1 s ; module-roles 22 / 0, 1 s ; roles-e2e 12 ok / 0 ko / 1 skip (preuve de livraison non armée, opt-in `VF_ROLE_E2E_LIVRAISON=1`), 50 s ; vibeflow-update 93 / 0, 142 s. Aucune au-delà de 600 s.
- **Flake nommé** : au premier passage, `test-dev-orchestrator.sh` rc 1, 523 s, `397 OK / 1 KO` sur `T2e-A` (cas de Node, fichier non touché par la phase) avec `echo: write error: Broken pipe`, pendant que la machine portait une charge de 76 à 84 (autres sessions). Contre-preuve : rejeu isolé à charge 7, rc 0, 398 / 0, 43 s.
- Parité mawk (A1) : non rejouable (démon Docker arrêté, ni mawk ni gawk) ; la CI de la PR en est le témoin.

## Périmètre
`perimetre=ok` (liste blanche du plan, aucun `INTERDIT`). `vf-dev-manager.md`, `scripts/hooks/`, `.github/`, `VERSION` racine, manifestes de plugin, compartiment `gouvernance`, `manual/toc.yml` : diff vide contre PB. Sentinelles `-armed` touchées : 0 ; `SKILL.md` neuf : 0 ; registre d'instructions : 1 ajout (`vf-product-architect.md 81 17`), 0 retrait ; aucun tag sur HEAD. Non-régression solo : `check-phase-validation.sh --ws fiabilite` phases 59 et 60 rc 0 `marqueur=absent`, 0 marqueur dans le ROADMAP réel.

## Exigences cochées
ARCG-02 (60-01, suite 46 ok) ; ARCG-03 et ARCG-04 (60-06, T45) ; ARCG-05 (60-06, hypothèses P60-H-01..04 à confirmer) ; ARCG-06 (60-02, 60-04) ; ARCG-07 (60-02, 34 cas, 9 mutants) ; ARCG-08 (60-05, bundle 104 ok, aucun run réel) ; ARCG-10 (60-08, manuel rc 0) ; ARCG-11 (60-07, 60-09, porte ci-dessus). Neuf cochées, preuves citées à la traçabilité.
- **ARCG-01 reste décochée, `Partial`** (P60-PL-26) : marqueur, moteur et verbe prouvés ; la pose « proposée » par l'équipe n'est prouvée que par le texte et le lien manager → contrat.
- **ARCG-09 reste décochée, `Partial`** (écart au plan, qui en attendait dix) : tout est vert sauf « zéro nom de client », dont le contrôle `check-livraison-58.sh clients --base 2649ccd4` rend **2, NON-VÉRIFIABLE, en attente de la liste** (hors dépôt) ; un code 2 n'est jamais un vert (précédent RLPO-11).

## Dettes ouvertes
1. Volet pose d'ARCG-01 non prouvé mécaniquement (P60-PL-26) : un run réel de mission, ou acceptation par Samuel.
2. Critère 6 `clients` en code 2 : dépôt de la liste par Samuel, puis rejeu du contrôle ; ARCG-09 reste partielle d'ici là.
3. Aucun run réel du worker `vf-product-architect` ni de `vf-coder`, `vf-auto` ou du head sur une étape proposée ; preuve par textes ancrés et commandes citées exécutées.
4. Parité mawk à trancher par la CI de la PR.

## Deviations from Plan
- [Rule 3 - outillage] Les `<verify>` du plan utilisent `git diff` nu, que le hook rtk de ce poste réécrit (sortie reformatée, premier calcul `ajouts=0 retraits=0` faussement bas) ; contrôles rejoués en `rtk proxy git diff` : `ajouts=1 retraits=0`, protégés intacts.
- ARCG-09 non cochée (voir ci-dessus), contre dix cochées attendues. STATE : `state_head` laissé tel quel.

## Suite
Hors de ce plan : PR (ouverte par le manager), relecture adverse SOBR-04, revue code owner `@picmakpro` attendue sur le registre d'instructions (rulesets posés), merge, minor racine, tag et release. Collision de version possible avec la Phase 45 (O-7). À confirmer par Samuel : P60-H-01 à P60-H-04, O-8, P60-PL-06 ; run réel du flux produit complet (geste humain de P59-D-11).

## Self-Check: PASSED
Commit du ledger `4c2344dc` présent ; trois fichiers du ledger commités ; STATE comparé à sa sauvegarde (frontmatter non replié, compteurs 36 → 45 plans, 3 → 4 phases).
