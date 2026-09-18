---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 16
subsystem: infra
tags: [ci, bash, git, gate, gate-touche, testing]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t (plan 41-14)
    provides: "structure et convention de `scripts/check-baseline-arbitrage.sh` (en-tête, contrat
      de codes de sortie, cascade de résolution de base nommée, patron `ok`/`ko` de la suite) —
      reprise à l'identique pour `check-gate-touche.sh`"
provides:
  - "scripts/check-gate-touche.sh — garde G-2 (PROT-05) : une PR qui touche la surface de gate
    (gates, suites, `.github/workflows/ci.yml`, `scripts/hooks/`) sans marqueur déclaratif
    `Gate-Touche:` dans un commit non-merge de la branche rend rc 1"
  - "scripts/tests/test-check-gate-touche.sh — suite QUAL-01, 29 assertions, cinq mutants
    opposables (MUT-1 à MUT-5)"
  - "étape `check-gate-touche` dans le job `gates` de `.github/workflows/ci.yml`, à quatre
    bascules de fixture isolées"
  - "CHANGELOG.md § Non releasé — entrée G-2 sous celle de G-1"
affects: [41-17, 41-18, 41-19]

# Actuals
actuals:
  tokens: null
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Reprise à l'identique du patron `check-baseline-arbitrage.sh` : cascade de résolution de
      base nommée, `git merge-base` jamais l'adjacence du journal, fixtures 100% jetables
      (`mktemp -d`, `git init -q -b main`, identité par `-c`)"
    - "`awk -v` réintroduit un échappement C/POSIX des antislashs qui cassait la comparaison
      exacte des motifs de la comparaison « appartenance à la surface » dans `make_mutant` de la
      suite — corrigé en passant les motifs par `ENVIRON` plutôt que par variable `-v` (commit
      `633be34`)"

key-files:
  created:
    - scripts/check-gate-touche.sh
    - scripts/tests/test-check-gate-touche.sh
  modified:
    - .github/workflows/ci.yml
    - CHANGELOG.md
    - README.md
    - README.fr.md

key-decisions:
  - "Périmètre sans admin (option (a)) : arbitrage Samuel, AskUserQuestion session principale,
    2026-09-17 — repris tel quel de 41-14, inchangé par ce plan."
  - "Couverture rétroactive de la branche : DÉJÀ ACQUISE sans commit de documentation
    supplémentaire. La mesure du dépôt réel après la Task 3 rend rc 0, avec
    `chemins_surface=5` et `marqueurs_conformes=9/10` — les trailers `Gate-Touche:` portés par
    les deux premiers commits de ce plan (`9d7d461`, `633be34`) suffisent à couvrir tous les
    chemins de surface touchés par la Phase 41 jusqu'ici. Le 10e trailer non conforme est un
    trailer pré-existant du plan 41-14 qui déclare deux chemins séparés par une virgule dans un
    seul champ au lieu d'un trailer par chemin — non conforme à la grammaire stricte du trailer,
    mais non bloquant puisque les chemins qu'il visait restent couverts par ailleurs (aucune
    conduite corrective engagée, hors périmètre de ce plan)."
  - "Les cinq classes de la surface de gate sont écrites en toutes lettres dans le script :
    `plugin/conductor/scripts/check-*.sh`, `scripts/check-*.sh`, leurs suites
    `plugin/conductor/scripts/tests/test-*.sh` et `scripts/tests/test-*.sh` (une seule classe
    combinée), `.github/workflows/ci.yml` (chemin exact), et tout chemin sous `scripts/hooks/`.
    Les gates des autres modules sont hors surface par l'arbitrage du périmètre, pas par oubli —
    contrôle négatif exercé par la suite."
  - "Le marqueur `Gate-Touche:` est déclaratif : la garde vérifie sa présence et sa forme
    (séparateur ` — ` nominal ou ` - ` accepté, raison d'au moins 10 caractères non blancs),
    jamais la véracité de la raison citée."
  - "Portée branche : le trailer peut vivre dans n'importe quel commit non-merge de la plage
    `<base>..HEAD`, pas nécessairement celui qui touche le chemin — c'est ce qui rend couvrable,
    par un commit ultérieur, un chemin touché avant l'existence de la garde (les commits du plan
    41-14 en particulier)."

requirements-completed: [PROT-05, QUAL-01]

coverage:
  - id: D1
    description: "scripts/check-gate-touche.sh — cinq verdicts (DECLARE, CHEMIN-NON-DECLARE,
      MARQUEUR-MAL-FORME, RIEN-A-JUGER, PLAGE-VIDE), cinq codes de sortie (0/1/2/3/64), cascade de
      résolution de base identique à G-1"
    requirement: PROT-05
    verification:
      - kind: other
        ref: "bash -n scripts/check-gate-touche.sh ; rc 64 sur argument inconnu ; dépôt réel rc 0
          ou 3 avec ligne `decouverte:` ; bascule isolée rouge (rc 1, CHEMIN-NON-DECLARE)"
        status: pass
    human_judgment: false
  - id: D2
    description: "scripts/tests/test-check-gate-touche.sh — suite QUAL-01, 29 assertions, cinq
      mutants opposables MUT-1 à MUT-5, chacun tracé en forme canonique
      `✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y>`"
    requirement: QUAL-01
    verification:
      - kind: unit
        ref: "scripts/tests/test-check-gate-touche.sh (29 assertions vertes, 0 ko, MUT-1 à MUT-5
          tués)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Étape `check-gate-touche` dans le job `gates`, quatre bascules isolées sur dépôt
      jetable reconstruit depuis zéro (couvert → rc 0, non déclaré → rc 1 CHEMIN-NON-DECLARE,
      trailer mal formé → rc 1 MARQUEUR-MAL-FORME, hors surface seul → rc 3 RIEN-A-JUGER), avant
      la mesure du dépôt réel"
    requirement: PROT-05
    verification:
      - kind: integration
        ref: "rejeu `gates` — étape verte, bilan de fixture à 0 écart sur 4 verdicts"
        status: pass
    human_judgment: false
  - id: D4
    description: "CHANGELOG.md § Non releasé porte l'entrée G-2 sous celle de G-1 ; VERSION racine
      intacte ; aucun bump de module"
    verification:
      - kind: other
        ref: "entrée G-2 (PROT-05, QUAL-01) présente sous § Non releasé, VERSION inchangée
          (v2.63.2)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Limite de fond écrite en en-tête du script, dans la suite, dans l'étape CI et au
      CHANGELOG : cette garde vit elle-même dans la surface qu'elle surveille"
    verification: []
    human_judgment: true
    rationale: "Propriété textuelle relue par un humain, pas assertée par une commande — le
      recensement `check-aucune-fermeture.sh` (plan 41-15) vérifie seulement qu'aucun texte
      produit n'associe cette garde ou O-3 à un mot d'achèvement, pas que la limite de fond est
      présente."
status: complete
completed: 2026-09-18
---

# Phase 41 Plan 16: G-2 — garde CI « la PR modifie ce qui la juge », marqueur déclaratif Gate-Touche Summary

**Garde in-repo bash `check-gate-touche.sh` qui rend visible et trace le fait qu'une PR modifie
CE QUI LA JUGE — un gate, sa suite, l'étape CI qui l'invoque, ou un hook — en exigeant un trailer
déclaratif `Gate-Touche: <chemin-ou-motif> — <raison>` dans un commit non-merge de la branche.
Cinq classes de surface, cinq verdicts, cinq codes de sortie. Suite QUAL-01 à 29 assertions et
cinq mutants opposables (MUT-1 à MUT-5). Câblée dans le job `gates` à quatre bascules isolées de
fixture. La couverture rétroactive de la branche est déjà acquise (rc 0) sans commit de
documentation supplémentaire — les trailers portés par les deux premiers commits de ce plan
suffisent.**

## Note de reconstitution

**Ce SUMMARY est rétroactif.** Les trois commits de ce plan (`9d7d461`, `633be34`, `c9439f1`)
sont sur la branche depuis leur exécution le 2026-09-18, vérifiés verts (suite QUAL-01 : 29
assertions, 0 ko ; cinq mutants tués ; rejeu `gates` et `tests` verts) — mais le fichier
`41-16-SUMMARY.md` que le plan exigeait en sortie n'a jamais été produit à l'époque, constaté
absent de tout l'historique du dépôt (`git log --oneline --all -- '*41-16-SUMMARY.md*'` ne rend
rien) par deux workers indépendants sur les plans 41-17 et 41-18. Ce fichier comble ce trou
documentaire (Rule 1 — gap documentaire) en décrivant ce qui a été RÉELLEMENT livré, relu
directement sur les trois artefacts (`scripts/check-gate-touche.sh`,
`scripts/tests/test-check-gate-touche.sh`, l'étape `check-gate-touche` de `ci.yml`) et les
messages complets des trois commits — jamais l'intention du `41-16-PLAN.md` seule. Aucun commit
41-16 déjà posé n'est réécrit ni amendé.

## Limite de fond

`scripts/check-gate-touche.sh` vit dans ce dépôt, dans la surface qu'il surveille lui-même
(`scripts/check-*.sh`) : ce script, comme sa suite `scripts/tests/test-check-gate-touche.sh` et
l'étape CI qui l'invoque, peuvent être modifiée par la PR qu'elle juge et rester verts. Il rend
visible et trace une modification de la surface de gate ; il ne verrouille rien. Aucun droit
admin n'existe dans ce périmètre pour poser une règle côté GitHub qui l'en empêcherait.

## Accomplissements

**Task 1 — le script et son étape CI à une bascule (`9d7d461`) :**

- `scripts/check-gate-touche.sh [--root DIR] [--base-ref REF]` : en-tête complet (origine —
  seconde phrase d'O-3 du `25-SECURITY.md` —, limite de fond, cinq classes de surface écrites en
  toutes lettres, borne nommée sur les gates des autres modules, nature déclarative du marqueur,
  portée branche, cascade de résolution de base, quatre comparaisons).
- Cinq verdicts : `DECLARE` (rc 0), `CHEMIN-NON-DECLARE` (rc 1, un par chemin non couvert),
  `MARQUEUR-MAL-FORME` (accompagne un rc 1 quand un trailer présent échoue la forme),
  `RIEN-A-JUGER` (rc 3, aucun chemin de surface touché), `PLAGE-VIDE` (rc 3, base égale HEAD ou
  zéro commit). Plus rc 2 (aucune ref `main` résoluble, hors d'un arbre git, ou diff imparsable)
  et rc 64 (erreur d'usage : argument inconnu, `--root`/`--base-ref` sans valeur, `--root`
  inexistant).
- Base dérivée par `git merge-base HEAD <ref>`, cascade nommée identique à G-1
  (`refs/remotes/origin/main`, `origin/main`, `refs/heads/main`, `main`).
- Comparaison 1 (appartenance à la surface) lit `git diff --name-status <base> HEAD` une seule
  fois ; comparaison 2 (récolte des marqueurs) lit tous les commits de
  `git rev-list <base>..HEAD`, merges compris ; comparaison 3 (forme du marqueur) exige séparateur
  ` — ` (nominal) ou ` - ` (accepté, borne ASCII) et raison ≥ 10 caractères non blancs ;
  comparaison 4 (correspondance) via `case "$chemin" in ($motif) …`, jamais `eval` ni regex
  construite par concaténation.
- Étape `check-gate-touche (G-2, PROT-05 — la PR modifie ce qui la juge)` insérée dans le job
  `gates` de `.github/workflows/ci.yml`, juste après `check-baseline-arbitrage`, à UNE bascule
  isolée (dépôt jetable, gate modifié sans trailer → rc 1 attendu, `CHEMIN-NON-DECLARE`), puis
  mesure du dépôt réel.

**Task 2 — suite QUAL-01, 29 assertions et cinq mutants (`633be34`) :**

- `scripts/tests/test-check-gate-touche.sh` : 29 assertions (11 PASS + 5 FAIL + 2 BRUYANT + 3
  SILENCE + 3 USAGE + 5 mutants), patron `ok`/`ko` à trois champs de
  `test-check-baseline-arbitrage.sh` (plan 41-14).
- Cinq mutants, un par comparaison : MUT-1 (retire la classe des suites `tests/test-*.sh`),
  MUT-2 (neutralise la recherche de trailer), MUT-3 (neutralise le contrôle de forme, raison vide
  acceptée), MUT-4 (rend la correspondance de motif universelle), MUT-5 (remplace `merge-base` par
  l'adjacence `HEAD^`) — chacun tracé en forme canonique
  `✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y>`.
- Correctif interne découvert pendant l'écriture : `awk -v` réintroduit un échappement
  C/POSIX des antislashs dans `make_mutant`, ce qui cassait la comparaison exacte des motifs de
  la comparaison 1 — corrigé en passant les motifs via `ENVIRON` plutôt que par variable `-v`
  (même commit).

**Task 3 — étape CI à quatre bascules, couverture rétroactive, CHANGELOG (`c9439f1`) :**

- L'étape `check-gate-touche` du job `gates` porte désormais QUATRE bascules isolées, chacune sur
  un dépôt jetable reconstruit depuis zéro par `write_base()`, une mutation à la fois : 1/4 chemin
  couvert par trailer conforme → rc 0 (`DECLARE`) ; 2/4 chemin sans trailer → rc 1
  (`CHEMIN-NON-DECLARE`) ; 3/4 trailer sans séparateur ni raison → rc 1 (`MARQUEUR-MAL-FORME`) ;
  4/4 seul un chemin hors surface touché → rc 3 (`RIEN-A-JUGER`). Bilan
  `== BILAN preuve fixture : <n> écart(s) sur 4 verdicts ==`, puis la mesure du dépôt réel.
- **Couverture rétroactive de la branche déjà acquise, sans commit de documentation
  supplémentaire.** La mesure du dépôt réel après cette tâche rend rc 0, avec
  `chemins_surface=5` et `marqueurs_conformes=9/10` : les trailers `Gate-Touche:` portés par
  les commits `9d7d461` et `633be34` de ce plan couvrent déjà tous les chemins de surface touchés
  par la Phase 41 à ce stade — aucune conduite de rattrapage (Task 3 du plan) n'a été nécessaire.
  Le 10e trailer lu, non conforme, est un trailer pré-existant du plan 41-14 qui déclare deux
  chemins séparés par une virgule dans un seul champ au lieu d'un trailer par chemin — non
  conforme à la grammaire stricte du marqueur, mais non bloquant : les chemins qu'il visait
  restent couverts par ailleurs.
- `CHANGELOG.md` § Non releasé : entrée G-2 (PROT-05, QUAL-01) ajoutée sous celle de G-1, nommant
  les cinq classes de surface, la forme du trailer, sa nature déclarative, la portée branche, la
  limite de fond, et l'autorisation « arbitrage Samuel, AskUserQuestion session principale,
  2026-09-17 ». Aucune section `## [vX.Y.Z]`, `VERSION` racine intacte, aucun bump de module.
- `README.md` / `README.fr.md` : compte de suites CI 80 → 81 (nouvelle suite
  `test-check-gate-touche.sh`).

## Task Commits

1. **Task 1 : G-2 bout en bout — script et étape CI à une bascule** — `9d7d461` (feat)
2. **Task 2 : suite QUAL-01, trois issues et cinq mutants opposables** — `633be34` (test)
3. **Task 3 : étape CI à quatre bascules, CHANGELOG, sync README** — `c9439f1` (feat)

Tous trois portent leurs propres trailers `Gate-Touche:` — la garde s'applique à elle-même dès sa
naissance, conformément à la contrainte de discipline du plan.

## Files Created/Modified

- `scripts/check-gate-touche.sh` — garde G-2 (nouveau)
- `scripts/tests/test-check-gate-touche.sh` — suite QUAL-01 (nouveau)
- `.github/workflows/ci.yml` — étape `check-gate-touche` dans le job `gates` (quatre bascules)
- `CHANGELOG.md` — entrée G-2 sous § Non releasé
- `README.md`, `README.fr.md` — compte de suites CI 80 → 81

## Decisions Made

Voir `key-decisions` en frontmatter. Aucune décision hors du cadre déjà arbitré dans
`41-CONTEXT.md` / `41-16-PLAN.md` — reprend intégralement le périmètre sans admin (option (a),
arbitrage Samuel, 2026-09-17) et le patron de style posé par G-1 (plan 41-14).

## Issues Encountered

Le fichier `41-16-SUMMARY.md` requis en sortie du plan n'a jamais été produit lors de l'exécution
d'origine — trou documentaire comblé rétroactivement par ce fichier, sans toucher aux trois
commits déjà posés ni rouvrir aucun arbitrage.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- G-2 est posée, prouvée et câblée — le patron (script `scripts/`, suite `scripts/tests/`, étape
  du job `gates`, trace au CHANGELOG, trailer `Gate-Touche:`) que G-3 (plan 41-17) a effectivement
  réutilisé est disponible et déjà éprouvé.
- Couverture rétroactive de la branche déjà acquise à ce stade (rc 0, `chemins_surface=5`,
  `marqueurs_conformes=9/10`) — le seul écart connu (un trailer 41-14 à deux chemins séparés par
  une virgule) est non bloquant et n'a motivé aucune conduite corrective dans ce plan.
- Aucun blocage connu pour 41-17/41-18/41-19.

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Plan: 16*
*Completed: 2026-09-18*

## Self-Check: PASSED

Fichiers vérifiés présents : `scripts/check-gate-touche.sh`,
`scripts/tests/test-check-gate-touche.sh`. Commits vérifiés présents dans l'historique :
`9d7d461`, `633be34`, `c9439f1`.
