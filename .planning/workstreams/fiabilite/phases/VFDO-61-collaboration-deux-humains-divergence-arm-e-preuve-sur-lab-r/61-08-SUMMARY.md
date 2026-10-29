---
phase: 61-collaboration-deux-humains-divergence-arm-e-preuve-sur-lab-r
plan: 08
subsystem: porte
tags: [porte-de-phase, ledger, replay-ci, perimetre, arret-avant-pr]
status: complete
requires: [61-01, 61-02, 61-03, 61-04, 61-05, 61-06, 61-07]
provides: [porte de phase 61 rejouee depuis ci.yml, ledger fiabilite a jour, COLB-08 decochee]
requirements: [COLB-01, COLB-02, COLB-03, COLB-04, COLB-05, COLB-06, COLB-07, COLB-09]
commits: 1
plan_head_before: b33eb0faec08904899c8cfe73651e61aae46ae55
plan_head_after: ba86145ad37b113a528f139594adecaf13ece206
actuals:
  tokens: 9000
  tasks: 3
  commits: 1
key-files:
  modified: [.planning/workstreams/fiabilite/REQUIREMENTS.md, .planning/workstreams/fiabilite/ROADMAP.md, .planning/workstreams/fiabilite/STATE.md]
completed: 2026-10-29
---

# Phase 61 Plan 08: porte rejouee, ledger a la main, arret avant la PR

COLB-01 a 07 cochees sur preuve rejouee, COLB-09 partielle, COLB-08 decochee ; aucune PR, aucun merge, aucun tag, aucune release.

## Porte de phase
**Job `gates`** (`replay-ci-jobs.sh --job gates --list` puis `--job gates`, alarme 1 800 s, 22 s) : 23 lignes extraites, **BILAN 20 rejouee(s), 3 sautee(s), 0 en echec, rc 0**. Rejouees rc 0 : check-agents strict (agents, AGENT.md, resolve-agents), check-skills, check-blueprints, check-version-sync, check-state-integrity, check-capability-activation, check-machine-paths, check-python-isolation, check-instruction-budget, gates workstream-aware sur arbre partitionne, check-divergence en CI (mutation rouge), check-planning-consumers-registered, check-baseline-arbitrage (G-1), check-gate-touche (G-2), check-ajout-retrait (SOBR-05), check-affirmation-non-mesuree (G-4), check-manual, check-push-sans-pr (fixture). **Sautees, nommees et non comptees vertes** : une action (ligne vide) et deux etapes `main` seulement (check-push-sans-pr mesure reelle, check-release-tag). Le manifeste check-agents (`verifie_le` 2026-10-22, 30 jours) est frais : aucune deviation.
**Budget** : `check-instruction-budget.sh` rc 0, `37 fichier(s), 0 depassement(s)`, `BOOTSTRAP ... ligne 2610` inchangee.
**Suites une a une** (bash, alarme 600 s, sorties en fichier ; rc / duree / bilan) :
test-divergence-deux-clones 0 / 20 s / 16 ok 0 ko · test-vibeflow-update-divergence 0 / 19 s / 27 ok 0 ko · test-vf-divergence-hook 0 / 33 s / 37 ok 0 ko · test-registres-role 0 / 4 s / 30 ok 0 ko · test-check-divergence 0 / 2 s / 22 ok 0 ko · test-vf-role 0 / 0 s / 26 ok 0 ko · test-check-planning-consumers-registered 0 / 2 s / 7 ok · test-consolidator 0 / 11 s / 102 PASS 0 FAIL · test-check-registres 0 / 1 s / 15 OK · test-seed-registres 0 / 1 s / 19 OK · test-decay 0 / 0 s / 27 PASS · test-vibeflow-update-role 0 / 51 s / 54 OK · test-roles-e2e 0 / 35 s / 12 OK 0 KO 1 SKIP (E2E-C2-AB, preuve de livraison non armee par `VF_ROLE_E2E_LIVRAISON`, skip anterieur a la phase) · test-manifest 0 / 18 s / 62 OK · test-vibeflow-update 0 / 145 s / 93 OK 0 KO. Aucune au-dela de 600 s.
**Autres gardes** : G-2 rc 0 (`marqueurs: lus=32 conformes=32`) ; `check-ajout-retrait --strict` rc 0 ; consommateurs rc 0 ; G-1 rc 0 (`CONFORME`) ; `check-version-sync` rc 0 (v2.72.0, 18 modules, 122 suites) ; `check-manual` rc 0.
**Controle `clients`** (`check-livraison-58.sh clients --base PB`) : **rc 2, « en attente de la liste »**, dette nommee, jamais comptee verte.
**Bases (P61-PL-15)** : base des gardes `merge-base HEAD origin/main` = `4a55c4af` ; base de phase PB = `f78062c0` ; **102 commits jugent en plus** (G-1, G-2 et SOBR-05 ont juge 134 commits, pas les 32 de la phase) ; 0 commit de PB absent de leur base.

## Perimetre
`perimetre=ok` : 56 chemins `PB..HEAD`, tous planifies ou sous `.planning/workstreams/fiabilite/`, aucun `INTERDIT`. Controles negatifs `f=0` (temoin : `git diff --quiet` rend 1 sur un fichier modifie) : `scripts/hooks`, `.github`, `VERSION`, manifestes, `gouvernance`, `manual/toc.yml`, `check-divergence.sh`, baselines (0 ligne), skill installeur, sentinelles `-armed`, agents, `AGENT.md`, `SKILL.md` intacts. Aucun tag sur HEAD.

## Exigences cochees
- COLB-01 : D2C-TRACE, D2C-TRACE-SOLO (61-01), VUD-ROLE-SOLO, VUD-UNINSTALL (61-04) ; lecture P61-H-01 a confirmer par Samuel.
- COLB-02 : D2C-TRACE-TIERS (`cmp -s`), VDH-ARM-TIERS, VDH-ARM-HOOKSPATH, VDH-ARM-WORKTREE (61-03).
- COLB-03 : VDH-RUN-ARBRE, VDH-INTROUVABLE (61-03), VUD-CACHE-SEUL (61-04), D2C-PIEGE (61-05).
- COLB-04 : VDH-JOURNAL, VDH-REWRITE, D2C-FF, D2C-REBASE, D2C-CONFORME (61-05) ; limites ecrites au manuel (61-07).
- COLB-05 : VUD-OPTOUT, VUD-OPTOUT-INV (61-04), manuel (61-07) ; lectures P61-PL-03 et P61-PL-08 a confirmer.
- COLB-06 : RRO-* 30 ok (six consommateurs avec et sans champ, quatre mutants), gabarits source puis copies (61-02), bumps (61-06), manuel (61-07).
- COLB-07 : test-divergence-deux-clones 16 ok, trois temoins rouges (D2C-TEMOIN-*), mutants prouves (61-05).
- **COLB-09 : PARTIELLE, decochee.** Baselines, skills, agents, hooks, `.github` et sentinelles intacts, G-2/SOBR-05/G-1 verts, porte verte ; seul le critere 6 (`clients`, rc 2) n'est pas verifiable.
- **COLB-08 : DECOCHEE, `Pending`.** Procedure `61-RECETTE-LAB-REEL.md` livree et son releve joue par D2C-RELEVE sur clones jetables ; aucun compte rendu de lab reel n'existe.

## Dettes ouvertes
- **COLB-08 : preuve humaine attendue** (P61-B-01 lab et humains, P61-B-02 trois semaines), cochable au depot du compte rendu dans le dossier de phase.
- Controle `clients` en code 2 (liste hors depot) ; confirmations P61-H-01, P61-PL-03, P61-PL-08 par Samuel.
- Parite uutils / mawk de ubuntu et Git Bash non mesurees ici (daemon docker arrete ; mawk 1.3.4 seul rejoue) : la CI de la PR tranche (AC-4).
- `test-guard-driver-lock-ws.sh` et `test-driver-lock-ws.sh` non joues (consigne de machine partagee ; hors liste du plan et absents du job `gates`).
- `detect-promotions.sh` : la ligne Role decale la fenetre de 500 caracteres (limite de 61-02, effet marginal).

## Suite
Gestes du manager, hors de ce plan : PR, relecture adverse SOBR-04 (diff `plugin/` depuis le tag precedent, sonde executee), merge, minor racine, tag annote et release GitHub. Collision possible avec les Phases 45 et 48 (consolidator, installeur) ; la Phase 60 n'est pas mergee sous la branche (conductor v1.51.0 non publie). Recette du lab reel et coche de COLB-08 par Samuel.

## Deviations from Plan
None - plan executed exactly as written. Mesures en `rtk proxy` (le hook rtk reecrit un `git diff` nu, comme en 60-09) ; un seul commit de ledger au lieu de deux : la porte et le ledger partagent ce SUMMARY, commite apres le ledger.

## Known Stubs
None.

## Self-Check: PASSED
SUMMARY 61-01 a 61-08 presents (8), plans coches au ROADMAP (8), COLB-08 decochee `Pending`, `check-state-integrity` rc 0, VERSION racine et manifestes identiques a PB, aucun tag.
