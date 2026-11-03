---
phase: 69-suivi-travail-en-cours-cockpit
plan: 09
status: complete
requirements: [CKPT-13, CKPT-14, CKPT-15, CKPT-16, CKPT-17, CKPT-18, CKPT-19, CKPT-20, CKPT-21, CKPT-22, CKPT-23, CKPT-24, CKPT-25, CKPT-26, CKPT-27, CKPT-28]
commits: [8bbe2634]
estimate:
  tokens: 80000
  raw_tokens: 80000
  tasks: 2
  confidence: low
actuals:
  tasks: 2
  note: tokens non mesurés par le moteur (exécution directe, hors gsd-execute-phase)
---

# 69-09 — documentation, bump du module et porte de phase

Aucune case d'exigence cochée (recette par `gsd-verify-work`), aucun bump racine, aucun tag, aucune release, aucune PR.

## Livré
- `README.md` / `README.fr.md` : phrase d'état courant 142 -> 146 suites (découverte : 146 `*/tests/test-*.sh`) ; lignes d'historique intactes.
- `plugin/cockpit/README.md` : « Les trois onglets », « Équipe au travail », confidentialité du transcript, contrats `avancement@1`, `who@2`, `transcript@1`, `equipe@1`, limites (masque au mieux sur la prose, jeton local, CI/merge/PR jamais lus, libellés provisoires), chaque affirmation renvoie à sa suite.
- Bump du module `cockpit` en `v1.1.0` (P69-D-26 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : `VERSION`, `module.json` (version et description), `CHANGELOG.md`, en-tête du README ; `check-version-sync.sh` exit 0.
- `69-VALIDATION.md` : `wave_0_complete: true`, colonne Statut remplie (24 lignes), cases signées sur preuve ; reste décochée la latence < 60 s (voir plus bas).

## Porte de phase

Rejouée après le commit de la correction d'audit de 69-06 (`0290b8ba`), arbre propre sur les quatre modules.

### Job `gates` (outil `replay-ci-jobs.sh`, étapes extraites de `ci.yml`, 23 lignes à `--list`)
Durée totale 22 s, code 0. Le moteur ne chronomètre pas chaque étape. `BILAN REJEU gates : 20 rejouee(s), 3 sautee(s), 0 en echec`.

- étape 2 : check-agents --strict sur chaque plugin/*/agents (découverte non vide) — rc=0
- étape 3 : check-agents --strict sur chaque plugin/*/AGENT.md (module mono-agent) — rc=0
- étape 4 : check-agents --resolve-agents=strict (monde fermé — union de tous les plugin/*/agents) — rc=0
- étape 5 : check-skills (classe d'invocation des skills — POCK-07, étape propre) — rc=0
- étape 6 : check-blueprints (le frontmatter cible passe le gate qu'il vise) — rc=0
- étape 7 : check-version-sync (canon VERSION ↔ plugin.json ↔ marketplace ↔ badges ↔ triade par module) — rc=0
- étape 8 : check-state-integrity (anti-régression du frontmatter .planning/STATE.md, ADR-063) — rc=0
- étape 9 : check-capability-activation (une entrée de doc ne promet pas un geste inerte, GSDA-09) — rc=0
- étape 10 : check-machine-paths (aucun chemin absolu de machine dans les fichiers versionnés) — rc=0
- étape 11 : check-python-isolation (aucune invocation inline de Python non isolée — hotfix H-1) — rc=0
- étape 12 : check-instruction-budget (BUDG-01/02/04/05, ADR-029 machine-enforced) — rc=0
- étape 13 : Gates workstream-aware sur un arbre RÉELLEMENT partitionné (fixture jetable) + non-régression — rc=0
- étape 14 : check-divergence.sh en CI (C17, 2026-09-10) — mutation rouge sur fixture divergente, pas seule — rc=0
- étape 15 : check-planning-consumers-registered (D-03 — un consommateur de chemin de planning oublié est V — rc=0
- étape 16 : check-baseline-arbitrage (G-1, PROT-04 — hausse de baseline sans arbitrage cité) — rc=0
- étape 17 : check-gate-touche (G-2, PROT-05 — la PR modifie ce qui la juge) — rc=0
- étape 18 : check-ajout-retrait (SOBR-05, consultatif — un ajout à la méthode dit ce qu'il retire) — rc=0
- étape 19 : check-affirmation-non-mesuree (G-4 — affirmation de prose non mesurée) — rc=0
- étape 20 : check-manual (cohérence du manuel utilisateur FR+EN — manual/.tools/check-manual.sh) — rc=0
- étape 21 : check-push-sans-pr (G-3 — preuve par fixture, sans condition) — rc=0
- sautée (action de checkout, sans commande)
- sautée (main seulement) : check-push-sans-pr (G-3, mesure réelle sur un push vers main)
- sautée (main seulement) : check-release-tag (VERSION doit être taggée et poussée)

### Suites du module (`ci-shard-suites.sh --all` filtré sur `plugin/cockpit/`, séquentiel) : 21 suites + installation, toutes à 0
- `test-cockpit-assemblage.sh` : code 0, 2s, 40 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-avancement.sh` : code 0, 4s, 51 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-chaine-xss.sh` : code 0, 31s, 22 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-chrome-fr.sh` : code 0, 2s, 26 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-direct.sh` : code 0, 48s, 75 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-equipe.sh` : code 0, 6s, 75 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-forme-claude.sh` : code 0, 4s, 56 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-hygiene.sh` : code 0, 20s, RÉSULTAT: 23 passées, 0 échouées, SAUTÉ : 0
- `test-cockpit-marque-blanche.sh` : code 0, 2s, 22 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-onglet-code.sh` : code 0, 2s, 18 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-projet.sh` : code 0, 23s, 35 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-questions.sh` : code 0, 9s, 56 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-reconnexion.sh` : code 0, 24s, 10 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-reseau.sh` : code 0, 7s, 15 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-responsive.sh` : code 0, 176s, 186 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-robustesse.sh` : code 0, 5s, 25 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-securite.sh` : code 0, 44s, 91 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-serveur.sh` : code 0, 18s, 66 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-transcript.sh` : code 0, 16s, 73 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-vendor.sh` : code 0, 3s, 77 PASS / 0 FAIL, SAUTÉ : 0
- `test-cockpit-who.sh` : code 0, 10s, 69 PASS / 0 FAIL, SAUTÉ : 0
- `test-vibeflow-update-cockpit.sh` : code 0, 9s, 11 ok, 0 ko, SAUTÉ : 0

Aucune suite sautée. T26.7 (clic « Lire le transcript » sous Chrome, `/Applications/Google Chrome.app` présent) : `✅ PASS — T26.7`. La suite `test-cockpit-hygiene.sh` rend « 23 passées » et H0 : aucun serveur ni Chrome ne survit. La seule occurrence de « SAUT » est le mot « sautées » d'une assertion de `securite` (FB3.1).

### Code d'exécution recopié
`fichiersExecution` contient `vf-cockpit-avancement.mjs`, `vf-cockpit-lecture.mjs`, `vf-cockpit-equipe.mjs`, `vf-cockpit-equipe-carte.mjs`, `vf-cockpit-transcript.mjs` : `OK-EXEC`. Suite d'installation I1 à I8 : 11 ok, 0 ko. Témoin réseau de CKPT-03 : `test-cockpit-reseau.sh` 15/0.

### Périmètre du diff (base `git merge-base origin/main HEAD` = `7079caad`)
72 chemins, tous sous `plugin/cockpit/`, `.planning/`, `.claude/agent-memory/`, `README.md`, `README.fr.md` : `OK-PERIMETRE`. `VERSION` racine, `plugin.json`, `marketplace.json` inchangés. Témoin du filtre (liste fautive avec `VERSION` racine) : le filtre rougit, `OK-TEMOIN-PERIMETRE`. Aucune case `CKPT-` cochée ni ligne `Complete` dans le diff de `REQUIREMENTS.md` : `OK-AUCUNE-CASE-CKPT`, après deux témoins rejetés par le filtre.

### Ordre suite -> trace -> code
Cinq paires vérifiées par `git merge-base --is-ancestor` : `OK-ORDRE` (5/5). Témoin inverse : `OK-TEMOIN-ORDRE`.

### Dérogation
Latence de retour < 60 s non tenue par `test-cockpit-responsive.sh` (176 s, Chrome) ; les 20 autres suites vont de 2 à 48 s. Case décochée dans `69-VALIDATION.md`.

## Questions ouvertes OQ-1 à OQ-10 (issue)
| OQ | Issue |
|----|-------|
| OQ-1 | P69-D-25 : couleur « en cours » + mot « à recetter » en tête du pied (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) |
| OQ-2 | page `/equipe.html` servie en mémoire, patch P24 de `serve.mjs` (décision du manager, vf-dev-manager, planification 2026-11-03) |
| OQ-3 | détails de `avancement@1` : `mission` nul sans DAG, vocabulaire de `reste`, pied du jalon (P69-PL-03, décision du manager) |
| OQ-4 | registre décisif, pas de verbe de lecture ajouté à `driver-lock.sh` (décision du manager) |
| OQ-5 | unicité stricte, citation de mandat structurée, ambigu = non rattaché (décision du manager) |
| OQ-6 | plan non fait = `todo` sauf nœud `running` (P69-PL-04, décision du manager) |
| OQ-7 | Bash = « lance une commande », cible vide (décision du manager) |
| OQ-8 | P69-D-26 : bump `v1.1.0` du module dans la phase (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) |
| OQ-9 | P69-D-27 : risque des secrets en prose accepté (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) |
| OQ-10 | règle (3) de D-05 implémentée par fixture seulement (P69-PL-05, décision du manager) |

Les décisions du manager sont rouvrables sur objection et ne valent pas arbitrage de Samuel.

## Assertions réécrites par conception dans la phase
- **P1.1, P1.2, P1.5** (69-01) : la règle STATE -> statut est retirée (CKPT-18) ; un plan sans nœud `running` est `todo` (P69-PL-04) ; le pied devient « N clos · N à recetter · N à faire · N % » (P69-PL-03).
- **W1.1, W4.1, W4.3, W10.1** (69-03) : `cockpit-who@1` devient `@2` (le contrat remplace `@1`, CKPT-28).
- **W8.6** (69-03) : « la fixture conforme rend lue » devient « un `meta.json` hors forme rend la source `forme-inconnue` » (CKPT-27 : un sous-agent hors forme suffit) ; W8.7 ajouté en témoin.
