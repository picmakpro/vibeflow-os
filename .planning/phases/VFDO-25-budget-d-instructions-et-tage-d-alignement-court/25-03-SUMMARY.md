---
phase: 25-budget-d-instructions-et-tage-d-alignement-court
plan: 03
subsystem: infra
tags: [ci, gate, documentation, version-bump]

requires: ["25-01", "25-02"]
provides:
  - "Étape CI check-instruction-budget dans le job gates de .github/workflows/ci.yml,
    avec preuve de discrimination sur fixture jetable (0/1/3/2) et traitement explicite
    des quatre codes"
  - "Catalogue conductor corrigé (D-05) et complété d'une entrée pour
    check-instruction-budget.sh, module conductor bumpé v1.37.0"
  - "Note datée sous ADR-029 et deux dettes différées inscrites au BACKLOG"
affects: [25-04]

estimate:
  tokens: 56000
  raw_tokens: 56000
  tasks: 3
  confidence: low

actuals:
  tokens: non mesurable (exécution en direct, hors gsd-execute-phase — aucun compteur de
    session à recopier)
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Étape CI en deux blocs : preuve de discrimination sur fixture jetable armée
      (patron check-divergence.sh en CI, Phase 39), puis dépôt réel avec case explicite
      sur les quatre codes de sortie — jamais de || true"
    - "Compteurs documentaires re-dérivés par exécution, croisés par deux moyens
      indépendants (find | awk et git ls-files) avant toute écriture en dur"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - plugin/conductor/README.md
    - plugin/conductor/VERSION
    - plugin/conductor/module.json
    - plugin/conductor/CHANGELOG.md
    - README.md
    - README.fr.md
    - docs/ADR.md
    - .planning/BACKLOG.md
---

## Ce qui a été livré

**Tâche 1 — étape CI (`.github/workflows/ci.yml`, commit `261e42c`).** Une étape neuve
`check-instruction-budget (BUDG-01/02, ADR-029 machine-enforced)` dans le job `gates`, insérée
entre `check-machine-paths` et les gates workstream. Bloc 1 : preuve de discrimination sur une
fixture jetable armée — fichier d'agent synthétique + baseline TSV construite depuis sa propre
mesure, puis quatre assertions dans l'ordre `0` (conforme) → `1` (mutation en place, une règle
ajoutée) → `3` (sentinelle retirée) → `2` (répertoire vide). Bloc 2 : invocation réelle sans
surcharge d'environnement, branchée sur la présence de la sentinelle — non armé : seul `3` est
accepté, tout autre code échoue (le ratchet se serait inversé) ; armé : `0` passe, `1`/`2`/tout
autre code échouent. Un seul `case` par branche, aucun `|| true`. Rejoué localement (corps
dé-indenté) : les quatre états de fixture rendent exactement `0/1/3/2`, et le dépôt réel (31
fichiers de corpus, sentinelle absente) rend `3` avec un `::warning::` — job vert, non bloquant.

**Tâche 2 — catalogue, bump, compteurs (commit `41a106d`).** Correction D-05 de la puce
`check-agents.sh` (retrait de « budget de préchargement », capacité renvoyée vers le nouveau
gate) et ajout d'une entrée de catalogue propre pour `check-instruction-budget.sh` (cinq codes,
ratchet, sentinelle non posée). Titre de section `## Scripts (27)` re-dérivé (était 26). Module
`conductor` bumpé `v1.36.0` → `v1.37.0` (VERSION, module.json, en-tête README), entrée CHANGELOG
`[v1.37.0]` déclarant en toutes lettres qu'aucune baseline n'est gravée et que la calibration
attend la Phase 40. Compteur de suites `README.md`/`README.fr.md` porté à 78 (était 77).
`scripts/check-version-sync.sh` rejoué : vert, et confirme lui-même les deux compteurs (triade
17 modules alignée, suites 78 des deux côtés) — une quatrième source de confirmation.

**Tâche 3 — traces documentaires (commit `b2d77c6`).** Note datée `**ADR-029 : enforcement
machine à partir de la Phase 25 (2026-09-15)**` ajoutée sous le tableau « ADR héritées les plus
citées » de `docs/ADR.md` (patron `ADR-065`), nommant le script, la sentinelle et la dépendance
à la Phase 40 ; l'entrée d'index ADR-029 est restée intacte (vérifiée : une seule occurrence,
caractère près). Section BACKLOG datée « Budget des SKILL.md et du bootstrap » avec le
déclencheur de reprise (extension du gate existant, pas un nouveau script), la piste tokens
estimés explicitement écartée (pas différée), et la remédiation nommée comme geste ultérieur.

## Compteurs re-dérivés — valeur et deux moyens

- **Scripts conductor : 27.** `find plugin/conductor/scripts -maxdepth 1 -type f -name '*.sh' |
  awk 'END{print NR}'` (répété via `rtk proxy find …`, même résultat) **et** `git ls-files
  'plugin/conductor/scripts/*.sh'` filtré sur la profondeur exacte — les deux moyens rendent 27.
- **Suites de tests des deux README racine : 78.** `find plugin scripts -type f -path
  '*/tests/test-*.sh' | awk 'END{print NR}'` (idem via `rtk proxy`) **et** `git ls-files | grep
  -E '/tests/test-.*\.sh$' | awk 'END{print NR}'` — les deux moyens rendent 78, et
  `scripts/check-version-sync.sh` confirme indépendamment cette même valeur des deux côtés
  (`README.md suites 78`, `README.fr.md suites 78`).

## Rejeu local de l'étape CI (corps dé-indenté, sortie non vide)

Corps extrait par la même logique que le gate `<verify>` de la tâche 1 (10 espaces d'indentation
retirés), passé à `bash` directement — sortie non vide à chaque étape :

```
== 1/4 fixture armée conforme : rc=0 ==
== 2/4 fixture MUTÉE (même arbre, une règle ajoutée) : rc=1 ==
== 3/4 sentinelle retirée : rc=3 ==
== 4/4 découverte vide : rc=2 ==
== BILAN preuve fixture : 0 écart(s) sur 4 verdicts (conforme, mutation, ratchet, vide) ==
== dépôt réel (checkout CI, sentinelle armée=0) : rc=3 ==
BILAN : 31 fichier(s), 0 depassement(s), 0 non verifiable(s), arme=non, code=3
::warning::check-instruction-budget : ratchet NON ARMÉ (sentinelle absente) — …
EXIT=0
```

## Gates rejoués avant de rendre (commande + exit code)

| Commande | Exit |
|---|---|
| `bash scripts/check-version-sync.sh` | 0 |
| `bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=<d>` (6 dossiers) | 0 (6/6) |
| `bash plugin/conductor/scripts/check-agents.sh --strict --file <f>` (6 `AGENT.md`) | 0 (6/6) |
| `bash plugin/conductor/scripts/check-agents.sh --strict --resolve-agents=strict …` (monde fermé) | 0 (6/6) |
| `bash plugin/conductor/scripts/check-state-integrity.sh --file .planning/STATE.md` | 0 |
| `bash plugin/dev-orchestrator/scripts/check-capability-activation.sh` | 0 |
| `bash scripts/check-machine-paths.sh` | 0 |
| Étape CI neuve (corps dé-indenté, rejeu direct) | 0 |
| Étape « Gates workstream-aware … » (corps dé-indenté, rejeu direct) | 0 |
| Étape « check-divergence.sh en CI » (corps dé-indenté, rejeu direct) | 0 |
| `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh` (suite frozen, non touchée) | 0 (30/30 ok) |

`check-release-tag.sh` non rejoué : conditionné à `push` sur `main`, hors mandat (release =
geste humain gaté).

## Intégrité du périmètre frozen

`cksum plugin/conductor/scripts/check-instruction-budget.sh` = `4164972968 16344` — identique à
la valeur communiquée en amont. `git status --short` sur ce fichier et sur
`plugin/conductor/scripts/tests/test-check-instruction-budget.sh` : vide (non touchés).

## Déviation déclarée minimale (hors périmètre du plan, commit séparé)

Deux entrées BACKLOG supplémentaires, datées du 2026-09-15, distinctes des deux dettes du cadrage
D-03 posées par la tâche 3 — issues des audits de cette mission même, non corrigées ici :

1. **Évasion de mesure du budget d'instructions par bloc de code fenced** : `count_instructions()`
   de `check-instruction-budget.sh` exclut le contenu entre triples backticks (design assumé,
   documenté dans le script) — une instruction impérative encadrée d'un bloc de code échappe donc
   au ratchet. Hors registre STRIDE actuel du gate.
2. **Blocs `<verify><automated>` de plan qui écrasent un script réel sans `trap`** : la tâche 1 de
   `25-02-PLAN.md:154` fait `cp`/écrasement/`mv` du gate réel sans filet ; une interruption entre
   l'écrasement et la restauration laisse un stub de 27 octets à la place du gate réel. À durcir
   (`trap … EXIT INT TERM`) lors d'une prochaine révision des scripts de vérification de plan.

Ces deux entrées vivent dans `.planning/BACKLOG.md`, à la suite de l'entrée « Budget des SKILL.md
et du bootstrap » posée par la tâche 3, dans un commit distinct pour garder le périmètre du plan
lisible séparément de cette déviation.


## Ce qui reste hors de ce plan (D-06 bis)

Aucune sentinelle, aucune baseline n'a été créée. Le plan 25-04 (calibration) est un checkpoint
bloquant qui attend la livraison de la Phase 40 — la première PR de la Phase 25 s'arrête
proprement ici.
