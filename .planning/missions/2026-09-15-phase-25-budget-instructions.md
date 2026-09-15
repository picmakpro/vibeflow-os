# Mission — Phase 25 « Budget d'instructions », vagues 1 à 3

- **Date** : 2026-09-15
- **Manager** : `vf-dev-manager`, verrou `mission-phase-25`, generation `DRIVER.lock.gen.1789472152.51445`
- **Mode** : superviser · **Design** : off
- **Branche** : `feat/phase-25-budget-instructions`, base `5583d3e` · **PR** : [#67](https://github.com/picmakpro/vibeflow-os/pull/67) — ouverte, **jamais mergée**
- **Plan de bataille** : `.planning/MISSION-25.dag.json` (13 nœuds)

## Gestes de démarrage

| Geste | Résultat |
|---|---|
| `driver-lock.sh acquire` | `acquired: true`, aucun autre driver |
| `check-mission-invariants.sh` | **exit 3 = SAIN** |
| Flags d'enchaînement | `gsd_run` ABSENT ; vérifiés par lecture de `.planning/config.json` : `_auto_chain_active=false`, `auto_advance=false` |
| Arbre tracké | propre |

## Déroulé — 13 nœuds, 1 réouverture

| Nœud | Verdict | Commande / preuve | SHA |
|---|---|---|---|
| `exec-01` (1er tour) | passed (**faux**) | 3 blocs `<verify>` verts | `ab5af42`, `393b022` |
| `revue-01` (1er tour) | **gaps_found** | 1 bloquant + 2 majeurs, reproduits par exécution | — |
| `audit-01` | passed | 7/7 menaces STRIDE vérifiées par exécution, fixtures à noms hostiles | — |
| `exec-01` (comblement) | passed | 6 témoins rouge→vert | `cca219b`, `fe8f858` |
| `revue-01` (tour 2, régime **full**) | passed | 6 vecteurs rejoués, contrôles négatifs `007`/`999999999` | — |
| `audit-01` (tour 2) | passed | injection par baseline hostile : témoins jamais créés | — |
| `exec-02` | passed | suite 30 cas, exit 0 | `ec8d8d7`, `9e15d29` |
| `revue-02` | passed | 4 mutants rejoués, `comm -3` : exactement 1 ligne mutée | — |
| `audit-02` | passed | **401 relevés `cksum`** pendant l'exécution ; SIGTERM → gate intact | — |
| `exec-03` | passed | 11 gates rejoués | `261e42c`, `41a106d`, `b2d77c6`, `6638804` |
| `revue-03` | passed | 78/78 suites, 6 gates, parseur YAML réel | — |
| `audit-03` | passed | **T-25-04 re-vérifié à son échéance** : 0 surcharge `VF_BUDGET_*` | — |
| `docs` | **gaps_found** | 1 fait faux + 3 conventions périmées | — |
| `gates-final` | passed | 10/10 étapes, 78/78 suites, `comm` sur les ensembles | — |
| `pr` | passed | STATE/ROADMAP/BACKLOG + 2 correctifs manager | `99c5b7a` → `717a614` + 2 |

**Réouverture unique** (`dag.sh reopen --id=exec-01`) : findings des deux juges fusionnés, 11 nœuds dépendants remis à blocked, `review_regime=full` forcé sur les trois nœuds de revue.

## Le bloquant, et pourquoi la revue était indispensable

Le premier jet du gate a rendu « tous critères verts ». La revue a trouvé que `bl_lines`/`bl_instr` (côté baseline) n'étaient **jamais** validés comme entiers, alors que le côté courant l'était. Sous `set -uo pipefail` **sans `-e`**, l'échec d'un `[ "$lines" -gt "$bl_lines" ]` n'arrête rien : `verdict` restait à son initialisation `"OK"`, code de sortie **0**. Quatre vecteurs : valeur non numérique, colonne manquante, CRLF résiduel, clé de baseline dupliquée. Un gate de ratchet qui rend vert sur une baseline corrompue est pire qu'absent.

Deux majeurs avec : frontmatter non ancré à `NR==1` (deux `---` isolés font disparaître les lignes entre eux — 2 comptées sur 3) et `DEPASSEMENT-ADR029` court-circuitant `SANS_BASELINE_COUNT` (rendait `1` là où le contrat exige `2`).

Les six vecteurs sont devenus des **cas nommés de non-régression** dans la suite (déviation déclarée que j'ai exigée), avec deux contrôles négatifs (`007`, `999999999`) parce que le correctif déplaçait le risque : un `2` de complaisance est aussi faux qu'un `0` de complaisance.

## Défauts attrapés par le manager

1. **`percent` a changé de base de calcul.** Le worker de clôture a recalculé `percent` sur 54/55 **plans** = 98. La valeur historique suit les **phases** : avant la mission, `completed_plans: 51/55` (= 93) avec `percent: 82` (= 9/11). `STATE.md` affirmait un jalon à 98 % avec deux phases sur onze restantes. `check-state-integrity.sh` ne l'a pas vu — il garde `completed_phases`, `completed_plans`, `total_plans`, `current_phase`, **pas `percent`**. Corrigé (`4b07c76`).
2. **Un décompte de commits écrit dans le fichier qu'il compte.** `stopped_at` annonçait « 14 commits », juste à la rédaction, faux dès le commit correctif qui le portait. Re-formulé sans total absolu, ancré sur des SHA — un fix par commit supplémentaire était structurellement impossible.

## Findings différés — tracés au BACKLOG, jamais corrigés en douce

| Sévérité | Constat | Échéance |
|---|---|---|
| **medium** | `plugin/validator/README.md:10` dit « 249 lignes, à 1 ligne du plafond ». **Réel : 250, marge zéro** (vérifié `awk` + `wc -l`). Le CHANGELOG du module dit juste. | **Avant l'armement Phase 40** — sinon une ligne ajoutée rend la CI rouge |
| medium | `CONVENTIONS.md:56` — codes « normalisés » contredits par 3 gates | phase d'hygiène |
| medium | `TESTING.md:29-32` et `:98` — 3 puces pour 10 étapes ; « tous les gates suivent F13 » faux | phase d'hygiène |
| faible | `ci.yml` bloc 1 : affectation héritant d'un `rc=2`, inoffensive sous `bash -e {0}`, mortelle sous `shell: bash`. `\|\| true` **interdit par le plan**. | durcissement |
| low | Évasion de mesure par bloc de code fenced | — |
| low | `<verify><automated>` de `25-02-PLAN.md:154` écrase le gate réel sans `trap` | — |

**Piège évité** : `manual/*/07-*/les-gates-machine.md` affirme que le plafond n'est pas vérifié « dans ton lab » — **reste VRAI** (le gate globe `plugin/*/agents/*.md`, absent d'un lab ; aucun hook ne le câble). Le « corriger » l'aurait rendu faux.

## Arbitrages — remontés par `SendMessage(main)`, **tranchés par Samuel le 2026-09-15**

Les deux points sont sortis de `human_needed`. Arbitrage Samuel, AskUserQuestion session principale, 2026-09-15 ; consignés au BACKLOG et dans `STATE.md` § Decisions sur la branche.

1. **`main` sans protection de branche** (`gh api rulesets` → `[]`, endpoint classique 404 avec `push:true, admin:false` — absence de configuration, pas un refus d'accès) : tout gate in-repo est neutralisable depuis la PR qu'il juge. Structurel et **antérieur** à cette phase, non nommé par son registre STRIDE.
   → **Tranché : phase dédiée « posture de protection du dépôt »**, prochain numéro libre (41), inscrite au ROADMAP par la session principale **après le merge de la PR #67** — délibérément, pour ne pas créer de conflit sur `ROADMAP.md` avec cette branche. Forme attendue : ruleset exigeant la CI verte avant merge, **jamais posé au passage d'une mission**. Ma recommandation initiale (tracer sans agir) est retenue et durcie en phase à part entière.
2. **T-25-SC accepté sans `25-SECURITY.md`** (précédents : `24-SECURITY.md`, `27-SECURITY.md`). `accept`/`low`, ne bloque pas `/gsd-ship`.
   → **Tranché : journal produit à la clôture de la phase, après 25-04**, par `/gsd-secure-phase` sur la phase complète, une fois la calibration livrée (donc après la Phase 40). Geste de clôture **daté et attendu**, pas une dette oubliée. Conforme à ma recommandation.

## Calibration — verbatim, jamais recalculée

| Plan | `estimate` | `actuals` |
|---|---|---|
| 25-01 | `{tokens: 68000, raw_tokens: 68000, tasks: 3, confidence: low}` | `{tokens: 3435, tasks: 3, commits: 1}` puis `non mesurable` |
| 25-02 | `{tokens: 62000, raw_tokens: 62000, tasks: 2, confidence: low}` | `non mesurable` |
| 25-03 | `{tokens: 56000, raw_tokens: 56000, tasks: 3, confidence: low}` | `{tokens: "non mesurable", tasks: 3, commits: 4}` |

**Réserve** : l'`actuals: 3435` du premier tour de 25-01 est **invérifiable et vraisemblablement faux** — le dispatch a consommé 211 073 tokens. Relayé verbatim par contrat ; ne pas l'agréger tel quel dans une calibration.

## Outillage — trois pièges mesurés dans cette mission

- **`find` tronque PAR INTERMITTENCE** : 21 résultats sur 78 chez un agent, 78 chez moi à la même minute. Deux agents l'ont constaté indépendamment. Un rejeu juste ne disculpe pas la mesure d'à côté.
- **Rejeu CI sous le mauvais shell** : `-eo pipefail` là où GitHub met `bash -e {0}` a produit **exit 2 avec zéro sortie** sur une étape saine — rouge entièrement fabriqué par le harnais.
- **`bash $VAR`** où `$VAR` contient script + arguments rend **127** sous le proxy ; invocation directe → 0. Autre rouge fabriqué.
- Le **watchdog** a crié `abandon detecte` pendant deux mandats de 31 min (TTL 1800 s) : battement remplacé par une boucle d'arrière-plan à 240 s, découplée des `dag.sh mark`.

## État final

`conductor` **v1.37.0** · `VERSION` racine **intacte à v2.61.0** · sentinelle et baseline **absentes** · `current_phase` **39** (précédent 34-06) · ROADMAP 3/4 plans cochés, `25-04` décoché et non préparé · arbre tracké propre.

## Next step

**`/gsd-plan-phase 40`**, puis la Phase 40 livrée. Le plan 25-04 (calibration, pose de la baseline et de la sentinelle) reste bloqué sur sa précondition machine — `name: vibeflow-head` dans `plugin/dev-orchestrator/AGENT.md` sur `main`, fausse aujourd'hui. À l'armement : traiter d'abord le `249 → 250` de `plugin/validator/README.md`.

Deux gestes appartiennent à la session principale, **après le merge de la PR #67** : inscrire la phase 41 « posture de protection du dépôt » au ROADMAP (arbitrage 1 ci-dessus), et retenir `/gsd-secure-phase` comme geste de clôture de la Phase 25 une fois 25-04 livré (arbitrage 2).
