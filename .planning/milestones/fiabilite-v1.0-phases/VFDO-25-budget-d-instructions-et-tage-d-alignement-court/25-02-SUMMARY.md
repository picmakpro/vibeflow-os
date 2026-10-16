---
phase: 25-budget-d-instructions-et-tage-d-alignement-court
plan: 02
subsystem: infra
tags: [bash, test, mutation, gate, ci]

requires: ["25-01"]
provides:
  - "plugin/conductor/scripts/tests/test-check-instruction-budget.sh — 30 cas nommés sur
    fixtures mktemp -d, quatre mutants vérifiés par cmp, témoin d'opposabilité"
affects: [25-03, 25-04]

estimate:
  tokens: 62000
  raw_tokens: 62000
  tasks: 2
  confidence: low

actuals:
  tokens: non mesurable (exécution en direct, hors gsd-execute-phase — aucun compteur de
    session à recopier)
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Constructeurs de fixture mktemp -d (mk_root/w_lines/w_armed/w_baseline/run), patron
      test-check-requirements-survival.sh"
    - "Mutants vérifiés cmp -s + bash -n avant opposition rc_mutant/rc_original, patron
      test-check-divergence.sh"
    - "Mutation par substitution littérale exacte via awk -v old=/new= (comparaison $0==old),
      jamais de regex fragile sur numéro de ligne"

key-files:
  created:
    - plugin/conductor/scripts/tests/test-check-instruction-budget.sh
  modified:
    - ".planning/phases/VFDO-25-budget-d-instructions-et-tage-d-alignement-court/25-02-SUMMARY.md"

key-decisions:
  - "Déviation déclarée minimale au plan (mandat vf-dev-manager, arbitrage Samuel, AskUserQuestion
    session principale, 2026-09-15) : six cas de non-régression nommés F1-1/F1-2/F1-3/F1-4/F2/F3,
    un par défaut réellement fermé en vague 1 (commit cca219b), plus deux contrôles négatifs
    (baseline zéro-paddée légitime « 007 », baseline légitime très grande) qui doivent rester
    OK/rc 0 — ajoutés au-delà du périmètre du plan 25-02 lui-même, sans toucher au gate."
  - "Chaque mutant construit sa PROPRE fixture dédiée (mk_root mut1..mut4), jamais de réutilisation
    de variables inter-tâches, pour rester autonome et lisible en isolation."
  - "Assertions de contenu combiné (message stderr + ligne de tableau) écrites dans l'ORDRE réel
    d'apparition dans le flux fusionné 2>&1 (stderr avant stdout, le gate imprime son rapport
    intégral juste avant `exit`) — un premier essai dans l'ordre inverse a fait échouer le cas
    BRUYANT (frontmatter), corrigé et revérifié avant commit."

patterns-established:
  - "Fixtures de baseline TSV toujours assemblées via printf '\\t' piped into w_baseline (jamais
    de tabulation littérale dans le script, insensible aux conversions d'éditeur)."

requirements-completed: [BUDG-01, BUDG-02, QUAL-01]

duration: n/a
completed: 2026-09-15
status: complete
---

# Phase 25 — Plan 02 : suite test-check-instruction-budget.sh

**QUAL-01 est tenu par preuve sur `check-instruction-budget.sh` : 30 cas nommés sur fixtures
jetables (dont 4 mutants vérifiés par `cmp` et un témoin d'opposabilité), zéro écriture dans le
dépôt réel, gate versionné inchangé.**

## Accomplissements

- Trois issues QUAL-01 exercées, chacune sur fixture jetable : PASS (conforme, rc 0), FAIL sur
  chaque métrique — instructions et lignes — (dépassement, rc 1), BRUYANT en deux formes
  (frontmatter jamais refermé, fichier illisible — rc 2, `NON-VERIFIABLE`). Contre-cas : un
  fichier sans frontmatter du tout se compte normalement, jamais `NON-VERIFIABLE`.
- Trois arêtes BUDG-02 : adjacence (`courant==baseline` → rc 0, `+1` → rc 1, `-1` → rc 0
  `MARGE`) ; vide en quatre sous-cas (0 fichier, baseline absente, baseline réduite à des
  commentaires, entrée orpheline — tous rc 2, jamais 0) ; plafond absolu ADR-029 (fichier à 251
  lignes ET baseline de lignes = 251 → `DEPASSEMENT-ADR029`, rc 1 — la baseline ne légalise
  jamais un dépassement du plafond) ; ordre (`LC_ALL=C sort`, deux exécutions consécutives au
  `cksum` identique).
- Ratchet (D-04) : une seule fixture en dépassement, non armée puis armée sans rien changer
  d'autre, prouve le basculement rc 3 → rc 1.
- Formes normatives BUDG-01 : fixtures de contrôle reprises à l'identique du plan 25-01
  (`INSTR=4`, `INSTR=2`) plus le cas Open Question 1 (`### Details` sous `## Iron Laws` referme
  le scope, niveau plat — `INSTR=1`).
- Quatre mutants `MUT-1`..`MUT-4` (Tâche 2), chacun généré par substitution littérale exacte
  (`awk -v old=/new=`), vérifié différent de l'original par `cmp -s` et syntaxiquement valide par
  `bash -n` avant toute opposition : `MUT-1` (comparaison INSTRUCTIONS), `MUT-2` (comparaison
  LIGNES), `MUT-3` (lecture de la sentinelle, force « non armé »), `MUT-4` (détection du
  frontmatter jamais refermé). Les deux métriques ont chacune leur preuve d'opposabilité (D-05).
- Témoin : le gate versionné remplacé par un script `exit 0` nu fait échouer la suite
  (`rc=1` ≠ `0`) — la suite n'est pas incapable de rendre rouge.

## Déviation déclarée — non-régression des trois défauts fermés en vague 1

Mandat de vague 2 explicite (au-delà du plan 25-02 initial) : six cas nommés, un par défaut
réellement trouvé et fermé par le commit `cca219b` de la vague 1, plus deux contrôles négatifs :

- `F1-1` baseline non numérique (`abc`) → `NON-VERIFIABLE`, rc 2 (avant fix : rc 0, `MARGE`).
- `F1-2` ligne de baseline à 2 colonnes → rc 2 (avant : rc 0).
- `F1-3` CR résiduel (CRLF) en fin de colonne → rc 2 (avant : rc 0).
- `F1-4` clé de baseline dupliquée pour un même chemin → rc 2 (avant : rc 0, 2ᵉ entrée lue en
  silence).
- `F2` deux `---` isolés dans un fichier sans frontmatter réel → le contenu entre les deux est
  COMPTÉ (`INSTR=1`), jamais exclu en silence.
- `F3` fichier > 250 lignes ET sans entrée de baseline, mode armé → rc 2 (contrat de couverture
  incomplète), jamais rc 1 (avant fix : `DEPASSEMENT-ADR029` masquait `SANS-BASELINE`).
- Contrôle négatif A : baseline légitime zéro-paddée (`007`) → reste `OK`, rc 0.
- Contrôle négatif B : baseline légitime très grande (`999999999`) → reste `MARGE`, rc 0.

Aucun de ces huit cas ne touche `check-instruction-budget.sh` : le gate est resté figé pendant
toute l'exécution de ce plan (`git diff --stat` vide sur ce fichier avant et après).

## Vérifications rejouées après le commit `ec8d8d7`

- `bash -n plugin/conductor/scripts/tests/test-check-instruction-budget.sh` → exit 0.
- Exécution directe → `30 ok, 0 ko`, exit 0.
- Deux exécutions consécutives → sorties strictement identiques (`cmp -s`).
- `git status --porcelain` avant/après exécution de la suite → identique (aucune écriture hors
  `mktemp -d`).
- Bloc `<verify>` Tâche 1 du plan 25-02 (rejoué verbatim) → `ISSUES-OK`, `succes=30 echecs=0`,
  `temoin_rc=1`.
- Bloc `<verify>` Tâche 2 du plan 25-02 (rejoué verbatim) → `MUTANTS-OK`, `mutants_verts=4`,
  `diff_occurrences=0`.
- `find plugin scripts -type f -path '*/tests/test-*.sh'` → le nouveau fichier est bien découvert
  par le motif CI.

## Hors périmètre de ce plan

Le câblage CI de la découverte (déjà générique, aucun changement requis dans `ci.yml`), le
catalogue/documentation (`plugin/conductor/README.md`, `CHANGELOG.md`, `VERSION`) et la
calibration de baseline/sentinelle — tous relèvent des plans 25-03/25-04, hors du périmètre de
fichiers de ce mandat.
