---
phase: 29-distiller-les-gains-icm-g1-g5-investigation-dag-sh-scope-d-a
plan: 02
subsystem: tooling
tags: [gate, drift, g3, adr-031, adr-055, adr-054]

requires:
  - phase: 29-01
    provides: "ledger .planning/REQUIREMENTS.md ICMD-03..06, baseline test-dag.sh verte"
provides:
  - "plugin/conductor/scripts/check-map-drift.sh : gate lint-only anti-drift carte↔disque (paires
    P1 carte de dossiers CLAUDE.md↔disque, P2 index _index.md/INDEX.md↔contenu direct de dossier)"
  - "plugin/conductor/scripts/tests/test-check-map-drift.sh : 49 cas, dont plancher NON VÉRIFIABLE,
    2 preuves par mutation attestées à l'octet (cmp -s), 4 cas ajoutés en correction ciblée exec-02
    tour 2 (comparaison par suffixe de basename en P2 sens B, token @/chemin/absolu en P1 sens A,
    nom de fichier à espace, nom à tiret initial), et 16 cas ajoutés en correction ciblée exec-02
    tour 3 (table normalize_path() : 13 formes d'écriture + 3 attestations rouge->vert rejouées
    contre 86c3b0c)"
affects: [29-05]

actuals:
  tasks: 3
  commits: 1

tech-stack:
  added: []
  patterns:
    - "wrapper git_safe() durci copié verbatim de check-doc-drift.sh:106-115"
    - "grammaire d'exit 0/1(réservé)/3/64 partagée avec check-doc-drift.sh/check-agents.sh"

key-files:
  created:
    - plugin/conductor/scripts/check-map-drift.sh
    - plugin/conductor/scripts/tests/test-check-map-drift.sh
  modified: []

key-decisions:
  - "Les 3 tâches du plan (tranche traçante P1, expansion P2+mutations, bornes en-tête) ont été
    livrées dans UN commit unique plutôt que 3 commits séquentiels : le script a été rédigé
    d'emblée avec sa section Bornes en tête (elle ne dépend d'aucun état intermédiaire de P1/P2),
    et scinder rétroactivement le fichier final en 3 diffs aurait recréé des états intermédiaires
    fictifs plutôt que de refléter un TDD réellement incrémental. Chaque acceptance criterion des
    3 tâches est vérifié sur le livrable final (voir Coverage)."
  - "--map borne le recensement à P1 seul (un seul fichier CLAUDE.md-like) ; P2 (index) reste
    toujours balayé par git ls-files sous --path, --map ou pas — cohérent avec le rôle de --map
    documenté dans l'en-tête (repli sur une carte isolée, jamais un mode de ciblage global)."
  - "Mutation attestée par comparaison de DEUX fichiers distincts (script pristine vs copie mutée
    produite par sed vers un nouveau fichier), jamais par édition in-place + restauration : le
    script réel sur disque n'est jamais touché pendant le test, cmp -s prouve seulement qu'aucune
    corruption accidentelle n'a eu lieu — répond littéralement à la contrainte 'jamais diff'."

patterns-established:
  - "Extraction de tokens de chemin par regex ancrée sur le SÉPARATEUR ('/) plutôt que par
    filtre après-coup : un mot entre accents graves sans '/' n'entre jamais dans le flux (motif
    de regex, pas une exception ajoutée) — réutilisable pour toute future paire carte↔disque."

requirements-completed: [ICMD-03, ICMD-04, ICMD-05, ICMD-06]

coverage:
  - id: D1
    description: "Paire P1 (CLAUDE.md↔disque) bidirectionnelle : pointeur @chemin absent, chemin
      entre accents graves absent, sous-dossier suivi par git non cité, carte propre à 0
      divergence avec compteur de cartes balayées"
    requirement: "ICMD-03"
    verification:
      - kind: other
        ref: "bash plugin/conductor/scripts/tests/test-check-map-drift.sh — cas P1-A, P1-A bis, P1-B, P1-clean"
        status: pass
  - id: D2
    description: "Paire P2 (index _index.md/INDEX.md↔contenu direct) bidirectionnelle, non
      récursive, l'index ne se cite jamais lui-même, un dossier sans index n'est pas une carte,
      cumul P1+P2 → 2 cartes balayées ; comparaison sur le CHEMIN RÉSOLU COMPLET (jamais un match
      par suffixe de basename — correction ciblée exec-02, D5-bis)"
    requirement: "ICMD-04"
    verification:
      - kind: other
        ref: "bash plugin/conductor/scripts/tests/test-check-map-drift.sh — cas P2-A, P2-B, P2-self, P2-non-récursif, P2-absent, P2-B-suffix, Cumul"
        status: pass
  - id: D3
    description: "Plancher anti-vert-à-vide : 0 carte balayée (cible sans carte, cible inexistante,
      hors arbre git) → NON VÉRIFIABLE + compteur 0, exit 3, jamais '0 divergence'"
    requirement: "ICMD-05"
    verification:
      - kind: other
        ref: "bash plugin/conductor/scripts/tests/test-check-map-drift.sh — 3 cas Plancher ; bash plugin/conductor/scripts/check-map-drift.sh --path \"$(mktemp -d)\" → rc=3, contient NON VÉRIFIABLE, ne contient pas '0 divergence'"
        status: pass
  - id: D4
    description: "Aucun mode correctif (ADR-031) : zéro occurrence de --update/--fix/--write dans
      le code, en-tête déclare l'absence de mode correctif et le garde-fou trois temps"
    requirement: "ICMD-06"
    verification:
      - kind: other
        ref: "grep -v '^#' check-map-drift.sh | grep -cE -- '--update|--fix|--write' → 0"
        status: pass
  - id: D5
    description: "Discriminance des deux paires prouvée par mutation, pas déclarée : neutraliser
      P1 sens B / P2 sens A rend le cas ciblé rouge ; le script original reste intact après
      mutation (cmp -s, pas diff)"
    requirement: "ICMD-04"
    verification:
      - kind: other
        ref: "bash plugin/conductor/scripts/tests/test-check-map-drift.sh — cas 'mutation P1' et 'mutation P2' (4 cas au total, 2 mutations + 2 vérifications cmp -s)"
        status: pass
  - id: D6
    description: "Durcissement git (V5) : wrapper git_safe() unique, une seule invocation git -C
      nue dans tout le fichier (celle du wrapper) ; ADR-054 respecté (aucun jq/grep -P/sed -i)"
    requirement: "ICMD-03, ICMD-04"
    verification:
      - kind: other
        ref: "grep -c git_safe → 7 (dont définition+6 appels) ; grep -v '^#' | grep -c 'git -C' → 1 ; grep -v '^#' | grep -cE 'jq |grep -P|sed -i' → 0"
        status: pass
  - id: D7
    description: "Zéro régression sur le socle dag.sh --scope (D-03) : dag.sh hors diff, gates
      voisins et suite test-dag.sh restent verts"
    requirement: "ICMD-03"
    verification:
      - kind: other
        ref: "git diff --name-only -- plugin/conductor/scripts/dag.sh → vide ; bash test-dag.sh → 99 PASS/0 FAIL ; bash test-check-doc-drift.sh → 21/21 ; bash test-check-agents.sh → 81/81"
        status: pass
  - id: D8
    description: "En-tête écrit ses bornes : 4 motifs de non-couverture nommés (skills:, DAG de
      mission, .planning/, qualité d'une carte), cite ADR-031 et ADR-055, ≥15 lignes via --help"
    requirement: "ICMD-06"
    verification:
      - kind: other
        ref: "bash check-map-drift.sh --help → contient 'Bornes', les 4 motifs, ADR-031, ADR-055 ; 63 lignes"
        status: pass
  - id: D9
    description: "Script sous 250 lignes de code hors commentaires, proportionné à ses deux paires"
    requirement: "ICMD-06"
    verification:
      - kind: other
        ref: "awk '!/^[ \\t]*#/' check-map-drift.sh | wc -l → 231 (après correction ciblée exec-02)"
        status: pass
  - id: D10
    description: "Correction ciblée exec-02 (4 findings, revue + audit indépendants, tous deux
      reproduits par expérience) : faux négatif P2 sens B (comparaison par suffixe de basename —
      refs/orphan.md masqué par une entrée refs/sub/orphan.md de même basename) ; faux positif P1
      sens A (token @/chemin/absolu jamais concaténé hors de $ROOT — désormais ignoré, documenté
      en commentaire) ; les 3 appels basename externes remplacés par ${f##*/} bash pur (robustesse
      sur un nom à tiret initial, sans dépendre de `basename -- `) ; 2 cas de suite manquants
      ajoutés réellement (nom à espace, nom à tiret initial) — la mitigation T-29-02-02 du threat
      model ne portait aucun cas correspondant avant ce correctif"
    requirement: "ICMD-03, ICMD-04, ICMD-06"
    verification:
      - kind: other
        ref: "bash plugin/conductor/scripts/tests/test-check-map-drift.sh — cas P2-B-suffix, P1-A-absolu, Robustesse (espace), Robustesse (tiret initial) ; 32/32 ; suites voisines non régressées (test-dag.sh 99/99, test-check-doc-drift.sh 21/21, test-check-agents.sh 81/81) ; dag.sh hors diff"
        status: pass
  - id: D11
    description: "Correction ciblée exec-02 tour 3 (3e défaut de la même famille en p2_sens_b,
      constaté à chaque tour par un juge externe) : la comparaison par './' de tête à un seul
      niveau (tour 2) laissait passer './/a.md' (le strip ne retire qu'un niveau, un '/' résiduel
      empêche le match). Remplacée par une fonction UNIQUE normalize_path() (bash pur, ADR-054)
      traitant la CLASSE — './' de tête un ou répété, '/' redondants en tête comme internes, '/'
      final — appliquée SYMÉTRIQUEMENT aux deux côtés de la comparaison p2_sens_b (entry ET $f).
      '../' explicitement NON résolu par choix documenté (même risque de traversée hors $ROOT que
      celui déjà écarté pour les tokens absolus en p1_sens_a). Couverte par une table de 13 formes
      (dont espace, tiret initial, %/$/&, / final, ../) plutôt que des cas copiés-collés, et 3
      attestations rouge->vert rejouées contre 86c3b0c (avant/après explicites). Le commentaire
      inexact de check-map-drift.sh (affirmant qu'un '/' final est déjà retiré par
      extract_p2_entries_raw, alors qu'une telle citation n'est jamais extraite — la regex exige
      '.md)' littéral) corrigé. p1_sens_a et p2_sens_a vérifiés : les deux passent par `-e`, le
      système de fichiers résout déjà './'/'//'/'/' final pour eux — asymétrie légitime documentée
      en commentaire, jamais un défaut caché. Une régression réelle a été détectée PENDANT
      l'écriture de la table elle-même (remplacement '\/' en position REMPLACEMENT de
      ${var//pat/repl} non déséchappé par bash — insérait un backslash littéral), corrigée avant
      commit via un slash porté par variable."
    requirement: "ICMD-03, ICMD-04"
    verification:
      - kind: other
        ref: "bash plugin/conductor/scripts/tests/test-check-map-drift.sh — 49/49 (16 cas ajoutés : 13 table normalize_path(), 3 attestations 86c3b0c) ; suites voisines non régressées (test-dag.sh 99/99, test-check-doc-drift.sh 21/21, test-check-agents.sh 81/81) ; dag.sh hors diff ; awk '!/^[ \\t]*#/' check-map-drift.sh | wc -l → 246 (< 250) ; grep -c git_safe → 7 ; grep -v '^#' | grep -c 'git -C' → 1"
        status: pass
---

## Accomplishments

- `plugin/conductor/scripts/check-map-drift.sh` créé : gate lint-only qui constate deux paires
  carte↔disque bidirectionnelles (P1 : `CLAUDE.md` vs sous-dossiers de premier niveau suivis par
  git ; P2 : `_index.md`/`INDEX.md` vs contenu `.md` direct — non récursif — de leur dossier).
  Wrapper `git_safe()` copié verbatim de `check-doc-drift.sh:106-115` (durcissement dépôt cloné
  hostile, V5). Grammaire d'exit `0`/`3`/`64` du dépôt, code `1` réservé et documenté comme jamais
  rendu par cette version. Plancher `NON VÉRIFIABLE` sur 0 carte balayée — jamais un vert-à-vide.
  Aucun mode correctif (ADR-031) ; aucun `jq`/`grep -P`/`sed -i` (ADR-054). En-tête `Bornes` :
  4 motifs de non-couverture (skills: d'agent, DAG de mission, `.planning/`, qualité d'une carte),
  citant ADR-031 et ADR-055.
- `plugin/conductor/scripts/tests/test-check-map-drift.sh` né avec le script (TDD) : 28 cas
  couvrant chaque comportement du plan — P1-A/A bis/B/clean, 3 cas Plancher (sans carte, cible
  inexistante, hors arbre git), 3 cas Ignorés (dossier point-préfixé, `node_modules`, identifiant
  entre accents graves sans `/`), grammaire d'exit complète, P2-A/B/self/non-récursif/absent, un
  cas de cumul (2 cartes balayées, 0 divergence), 2 preuves par mutation (P1 sens B, P2 sens A)
  chacune suivie d'une attestation `cmp -s` de non-corruption du script original, la section
  Bornes, et un garde final agrégeant les codes de sortie observés sur 5 fixtures (seuls `0`/`3`/`64`
  vus, jamais le `1` réservé).
- Non-régression D-03 vérifiée : `dag.sh` hors du diff, et les trois suites voisines restent
  vertes après le commit — `test-dag.sh` (99/99), `test-check-doc-drift.sh` (21/21),
  `test-check-agents.sh` (81/81).

## Deviations from Plan

- Les 3 tâches du plan (tranche traçante, expansion P2+mutations, bornes en-tête) ont été livrées
  en **un seul commit** au lieu de trois commits séquentiels. Le script a été rédigé d'un bloc,
  section Bornes incluse dès le départ (elle ne dépend d'aucun état intermédiaire de P1 ou P2), et
  a été vérifié vert dès la première exécution de la suite (28/28). Scinder rétroactivement le
  fichier final en 3 diffs aurait recréé des états intermédiaires fictifs plutôt que de refléter
  un historique réellement incrémental — chaque `acceptance_criteria` des 3 tâches est néanmoins
  vérifié individuellement dans la table `coverage` ci-dessus, sur le livrable final.
- Correction ciblée exec-02 (nœud rouvert) : une revue et un audit indépendants ont chacun reproduit
  par expérience 4 défauts sur le livrable initial — un faux négatif MAJEUR en P2 sens B (la
  comparaison `case "$entry" in *"$base")` matchait par suffixe de basename, si bien qu'une entrée
  `sub/orphan.md` citée masquait à tort un `refs/orphan.md` top-level jamais cité), un faux positif
  MINEUR en P1 sens A (un token `@/chemin/absolu` n'était jamais traité comme hors du domaine
  repo-relative de la carte et produisait une divergence même quand la cible absolue existait
  réellement sur le disque), un défaut de robustesse MEDIUM (3 appels externes `basename "$f"`
  cassaient sur un nom à tiret initial) et un vert-à-vide MEDIUM (la mitigation T-29-02-02 du
  threat model affirmait un cas de suite couvrant les noms à espace, sans qu'aucun n'existe
  réellement). Les 4 correctifs sont dans `check-map-drift.sh` (P2 sens B comparé sur le chemin
  résolu complet, token absolu ignoré et documenté en commentaire, les 3 `basename` remplacés par
  `${f##*/}` bash pur) et `test-check-map-drift.sh` (+4 cas : `P2-B-suffix`, `P1-A-absolu`,
  `Robustesse` espace, `Robustesse` tiret initial — 28 → 32 cas). Le cas `P2-B-suffix` a d'abord
  été rejoué sur le code d'avant correctif pour constater le rouge réel (`rc=3`, `0 divergence`,
  alors que `refs/orphan.md` aurait dû être signalé) avant d'appliquer le fix.
- Correction ciblée exec-02, **tour 3** (nœud rouvert une troisième fois) : le correctif du tour 2
  (strip d'un seul `./` de tête dans `p2_sens_b`) laissait passer `.//a.md` (un `/` résiduel après
  le strip). Remplacé par une fonction unique `normalize_path()` traitant la classe des formes
  d'écriture équivalentes (`./` de tête un ou répété, `/` redondants en tête/internes, `/` final),
  appliquée symétriquement aux deux côtés de la comparaison (`entry` et `$f`), avec un choix
  explicite documenté de ne pas résoudre `../` (même raison que le token absolu déjà écarté en
  `p1_sens_a`). Le commentaire de `check-map-drift.sh` affirmant qu'une citation à `/` final est
  « déjà retirée par `extract_p2_entries_raw` » a été corrigé (une telle citation n'est en réalité
  jamais extraite, la regex exigeant `.md)` littéral). `p1_sens_a` et `p2_sens_a` vérifiés : les
  deux passent par `-e`, donc le système de fichiers résout déjà ces formes pour eux — asymétrie
  légitime, désormais documentée en commentaire plutôt que silencieuse. Couverture : 13 cas en
  table (`normalize_path` extraite par `awk` depuis le script réel, jamais recopiée à la main) +
  3 attestations rouge→vert rejouées contre le commit `86c3b0c` (avant/après explicites) — 32 → 49
  cas. Une régression a été détectée PENDANT l'écriture de la table : `${p//\/\//\/}` insérait un
  backslash littéral (le `\/` en position remplacement n'est pas déséchappé par bash), corrigée
  avant commit via un slash porté par variable — la table elle-même a joué son rôle discriminant.

## Note pour le plan 29-05 (clôture de distribution)

`+1 suite` de test (`plugin/conductor/scripts/tests/test-check-map-drift.sh`) : le compteur
« N suites » des deux README racine devra être re-dérivé, comme annoncé par le plan 29-02
(`<artifacts_produced>` § Conséquence de distribution). Ce plan n'a touché à aucun README, aucun
hook, aucun agent — le câblage de `check-map-drift.sh` reste entièrement à faire en 29-05.
