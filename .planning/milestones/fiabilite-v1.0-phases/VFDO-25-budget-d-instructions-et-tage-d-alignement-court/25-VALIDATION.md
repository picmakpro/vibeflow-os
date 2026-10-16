---
phase: "25"
slug: "budget-d-instructions-et-tage-d-alignement-court"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-15"
---

# Phase 25 — Stratégie de validation

> Contrat de validation par phase, pour l'échantillonnage du retour pendant l'exécution.

---

## Infrastructure de test

| Propriété | Valeur |
|-----------|--------|
| **Framework** | Bash pur, zéro dépendance externe — harnais `ok()`/`ko(assertion, attendu, obtenu)` commun à toutes les suites du dépôt |
| **Fichier de configuration** | aucun — chaque suite est un exécutable autonome, découvert par le motif `*/tests/test-*.sh` |
| **Commande rapide** | `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh` |
| **Commande complète** | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort \| while IFS= read -r t; do bash "$t"; done` |
| **Durée estimée** | ~2 s pour la suite de la phase ; ~3 min pour la découverte complète |

---

## Taux d'échantillonnage

- **Après chaque commit de tâche** : `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh`
- **Après chaque vague** : boucle complète de découverte des suites
- **Avant `/gsd-verify-work`** : suite complète verte ET rejeu des commandes du job CI `gates` de
  `.github/workflows/ci.yml` (jamais la liste d'un rapport — `[[liste-de-gates-jamais-la-reference]]`)
- **Latence maximale de retour** : ~2 s

---

## Carte de vérification par tâche

| ID tâche | Plan | Vague | Exigence | Réf. menace | Comportement sûr | Type de test | Commande automatisée | Fichier existe | Statut |
|---|---|---|---|---|---|---|---|---|---|
| 25-01-01 | 01 | 1 | BUDG-01 | T-25-01 / T-25-02 | Découverte non vide assertée ; le gate n'écrit ni la sentinelle ni la baseline ; sortie déterministe | intégration (tracer) | `bash plugin/conductor/scripts/check-instruction-budget.sh ; test $? -eq 3` + égalité lignes-de-tableau / glob recompté | ❌ W0 | ⬜ pending |
| 25-01-02 | 01 | 1 | BUDG-01 | — | Le frontmatter, les titres et les blocs fenced ne peuvent pas gonfler le compte ; dédoublonnage | unit (fixture) | `bash plugin/conductor/scripts/check-instruction-budget.sh --path <fixture>` + assertions INSTR=4 et INSTR=2 | ❌ W0 | ⬜ pending |
| 25-01-03 | 01 | 1 | BUDG-02 | T-25-01 / T-25-03 | Cinq codes atteignables ; aucun vert par défaut ; plafond ADR-029 absolu | unit (matrice de fixtures) | matrice `decouverte-vide`→2, `frontmatter-non-referme`→2, `arme-sans-baseline`→2, `arme-egalite-adjacence`→0, `arme-depassement-instr`→1, `arme-depassement-lignes`→1, `arme-entree-orpheline`→2, `plafond-absolu-adr029`→1, `non-arme-malgre-depassement`→3, `argument-inconnu`→64 | ❌ W0 | ⬜ pending |
| 25-02-01 | 02 | 2 | BUDG-01, BUDG-02, QUAL-01 | T-25-09 | Trois issues exercées sur fixtures jetables ; la suite salit jamais le dépôt ; témoin de rougeur | unit + témoin | `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh` + témoin « gate vidé → suite rouge » | ❌ W0 | ⬜ pending |
| 25-02-02 | 02 | 2 | QUAL-01 | T-25-07 / T-25-08 | Quatre mutants `cmp`-vérifiés, deux métriques couvertes ; mutant non opposable = échec | mutation | `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh` + au moins 4 lignes `✓ MUT-` dont MUT-1..MUT-4 | ❌ W0 | ⬜ pending |
| 25-03-01 | 03 | 3 | BUDG-02, QUAL-01 | T-25-11 / T-25-12 / T-25-13 | `3` avertit sans bloquer ; `1` et `2` bloquent ; aucune surcharge d'environnement ; preuve de discrimination embarquée | intégration CI | extraction + `bash -n` du corps de l'étape, `rc` du dépôt réel = 3, et rejeu de la preuve de fixture (0 / 1 / 3 / 2) | ❌ W0 | ⬜ pending |
| 25-03-02 | 03 | 3 | BUDG-01 | T-25-14 / T-25-15 | Compteurs re-dérivés ; triade de module synchrone ; release racine intacte | intégration | `bash scripts/check-version-sync.sh` + égalité des deux compteurs re-dérivés + `git status` vide sur la méta de release | ❌ W0 | ⬜ pending |
| 25-03-03 | 03 | 3 | BUDG-01 | — | Note ADR datée sans réécriture de l'index ; dettes inscrites | documentaire vérifiée | greps ancrés sur `docs/ADR.md` (note datée, index intact) et `.planning/BACKLOG.md` (entrée datée) | ❌ W0 | ⬜ pending |
| 25-04-01 | 04 | 4 | BUDG-02 | T-25-18 | Précondition machine-vérifiable avant tout geste one-way | checkpoint bloquant humain | `git show origin/main:plugin/dev-orchestrator/AGENT.md \| grep -c '^name: vibeflow-head'` = 1 | n/a | ⬜ pending |
| 25-04-02 | 04 | 4 | BUDG-01, BUDG-02 | T-25-16 / T-25-17 / T-25-19 / T-25-20 | Gravure sur mesure fraîche ; aucune baseline de lignes > 250 ; armement vert immédiat ; même commit | intégration | baseline complète + `bash plugin/conductor/scripts/check-instruction-budget.sh ; test $? -eq 0` + suite verte + deux chemins dans `git show --name-only HEAD` | ❌ W0 | ⬜ pending |
| 25-04-03 | 04 | 4 | BUDG-01, BUDG-02, QUAL-01 | T-25-21 | Ledger fermé sur pièces datées ; STATE édité à la main | documentaire vérifiée | `check-state-integrity.sh --file .planning/STATE.md` + `check-machine-paths.sh` + coches datées au ledger | ❌ W0 | ⬜ pending |

*Statut : ⬜ pending · ✅ vert · ❌ rouge · ⚠️ instable*

---

## Prérequis Wave 0

- [ ] `plugin/conductor/scripts/check-instruction-budget.sh` — n'existe pas encore (créé par 25-01, tâche 1)
- [ ] `plugin/conductor/scripts/tests/test-check-instruction-budget.sh` — n'existe pas encore (créé par 25-02, tâche 1) ; squelette repris de `test-check-divergence.sh` (mutants `cmp`) et `test-check-requirements-survival.sh` (issues multiples, fixtures)
- [ ] Fixtures synthétiques (frontmatter non refermé, frontmatter absent, puces sous titre de règles, fichier à 251 lignes) — construites dans un `mktemp -d` par la suite, jamais versionnées
- [ ] `.planning/instruction-budget-baselines.tsv` et `.planning/.instruction-budget-armed` — **ne doivent PAS être créés avant le plan 25-04** (checkpoint bloquant, D-06 bis)

Aucun framework à installer : l'infrastructure bash existante couvre toutes les exigences de la
phase.

---

## Vérifications manuelles

| Comportement | Exigence | Pourquoi manuel | Instructions |
|---|---|---|---|
| Autorisation de graver les baselines (geste one-way) | BUDG-02 | Décision humaine par construction (ADR-031, D-06 / D-06 bis) : aucune machine ne peut décider que le corpus est figé | Lire le rapport du gate en mode non armé, vérifier la précondition `name: vibeflow-head` sur `origin/main`, repérer tout fichier au-dessus de 250 lignes, puis répondre A, B ou C au checkpoint du plan 25-04 |
| Lecture du journal CI en mode non armé | BUDG-02 | Le comportement « avertit sans bloquer » se constate sur un run réel de la PR, pas localement | Sur la PR de la première livraison, ouvrir le job `gates`, vérifier que l'étape `check-instruction-budget` imprime le tableau complet, émet un `::warning::` et que le job reste vert |

---

## Ce que cette phase refuse de compter comme une preuve

- Un compte de corpus recopié d'un document de cadrage ou de recherche : toute valeur est
  re-dérivée par exécution au moment où elle est vérifiée (leçon Phase 34).
- Un vérificateur qui ne peut pas rendre rouge : chaque suite porte son témoin, et chaque métrique
  son mutant `cmp`-vérifié (`[[preuve-incapable-de-rendre-rouge]]`).
- Une liste de gates issue d'un rapport : la référence est le job `gates` de `ci.yml`, rejoué
  commande par commande (`[[liste-de-gates-jamais-la-reference]]`).
- Un `| wc -l` sur une sortie potentiellement vide : `rtk` transforme le vide en une ligne — compter
  par `awk 'END{print NR}'` ou `grep -c` (`[[rtk-fausse-les-verifications-d-etat]]`).
