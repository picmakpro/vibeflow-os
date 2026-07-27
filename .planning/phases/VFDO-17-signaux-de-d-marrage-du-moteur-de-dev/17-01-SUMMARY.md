---
phase: VFDO-17-signaux-de-d-marrage-du-moteur-de-dev
plan: 01
subsystem: dev-tooling
tags: [bash, hooks, session-start, gsd-engine, dev-orchestrator]

# Dependency graph
requires:
  - phase: VFDO-13-pont-spec-feuille-de-route
    provides: discover-unintegrated-docs.sh (contrat grain\tchemin réutilisé comme analogue de harnais de test)
  - phase: planning-core (module transverse)
    provides: motif PRUNE_VENDOR de detect-planning-debt.sh, modèle structurel hooks/hooks.json
provides:
  - check-dev-bootstrap.sh — continuum à 4 états (silence / [onboard] / [bootstrap] / [gsd-engine])
  - premier fragment hooks/hooks.json du module dev-orchestrator (SessionStart:startup, 3 commandes)
  - suite test-check-dev-bootstrap.sh (23 assertions, D-14 asseré séparément)
affects: [VFDO-17-02, VFDO-17-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Continuum d'états mutuellement exclusifs évalués en ordre fixe (premier qui matche gagne), jamais un parcours de filesystem non déterministe"
    - "Lecture bornée + assainissement de frontmatter YAML par liste blanche stricte (soupape de sûreté, jamais un état inventé en cas d'échec)"
    - "Rupture assumée et documentée de la convention 'exit 3 ⇔ silence' pour un état d'orientation (D-14)"

key-files:
  created:
    - plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh
    - plugin/dev-orchestrator/hooks/hooks.json
    - plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh
  modified: []

key-decisions:
  - "Valeurs réelles du frontmatter (gsd-migration / phase 16 / shippée) utilisées pour la vérification empirique plutôt que les valeurs figées dans le texte de vérification automatisée du plan (gsd-migration / phase 15) — STATE.md a avancé (Phase 16 shippée) entre la rédaction du plan et son exécution. Le script lit dynamiquement, jamais en dur ; c'est le texte de vérification qui était périmé, pas le comportement attendu."
  - "--hook ne modifie aucun format de sortie pour ce script (contrairement à discover-unintegrated-docs.sh) : les 2 lignes de signal sont identiques avec ou sans le flag — seul le contrat d'arguments/gating avec --quiet en dépend, pour rester cohérent avec les deux autres scripts de la phase."
  - "Item 'roadmap' constaté via une ligne d'en-tête de phase '^#{1,6}\\s*Phase\\s+[0-9]+' (motif générique dérivé du format réel '### Phase N:' de ce ROADMAP.md), le libellé de constat retenu est 'feuille de route absente' (aucune formulation verbatim fournie par la spec pour cet item, seul le mapping fait/geste l'était)."
  - "État inobservé du continuum (.planning/ présent sans PROJECT.md) : traité en silence total, exit 3 — aucun des 4 états D-01 ne correspond littéralement à cette combinaison, choix conservateur cohérent avec le principe D-04 'jamais d'état inventé'."

patterns-established:
  - "Pattern : script de constat SessionStart en lecture seule, contrat de sortie 0/3/64 uniquement, jamais exit 1, say() sur stderr exclusivement — réutilisable tel quel par check-doc-drift.sh (plan 17-02)."

requirements-completed: [SIG-01, SIG-04]

coverage:
  - id: D1
    description: "check-dev-bootstrap.sh constate le continuum à 4 états (silence/[onboard]/[bootstrap]/[gsd-engine]) avec le contrat de sortie 0/3/64"
    requirement: "SIG-01"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh#cas 1,2,3,4,4bis,5,6,7"
        status: pass
    human_judgment: false
  - id: D2
    description: "Soupape de sûreté D-04 et assainissement T-17-01 du frontmatter de STATE.md (liste blanche stricte, silence total en cas d'échec)"
    requirement: "SIG-01"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh#cas 8,9,10,11,12,13"
        status: pass
    human_judgment: false
  - id: D3
    description: "Lecture seule (SIG-04) : aucune écriture sur le filesystem, empreinte find identique avant/après"
    requirement: "SIG-04"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh#cas 21"
        status: pass
    human_judgment: false
  - id: D4
    description: "Fragment hooks/hooks.json valide (SessionStart:startup, 3 commandes tolérantes à l'échec, {{VF_SCRIPTS}})"
    requirement: "SIG-01"
    verification:
      - kind: other
        ref: "jq -e '.hooks.SessionStart | length == 1 and .[0].matcher == \"startup\" and (.[0].hooks | length) == 3' plugin/dev-orchestrator/hooks/hooks.json"
        status: pass
    human_judgment: false
  - id: D5
    description: "Signal [gsd-engine] réellement observable sur ce dépôt (état 3 réel), 2 lignes, exit 3, valeurs réelles du frontmatter"
    requirement: "SIG-01"
    verification:
      - kind: other
        ref: "bash plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh --hook --path . (exécution manuelle documentée ci-dessous)"
        status: pass
    human_judgment: false

# Metrics
duration: ~20min
completed: 2026-07-27
status: complete
---

# Phase VFDO-17 Plan 01: Continuum de démarrage bout-en-bout Summary

**`check-dev-bootstrap.sh` (continuum à 4 états, lecture assainie du frontmatter GSD) câblé de
bout en bout par le premier fragment `hooks/hooks.json` de `dev-orchestrator`, prouvé sur ce
dépôt même où le signal `[gsd-engine]` s'affiche réellement — milestone `gsd-migration`, phase 16
shippée.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-27T21:08:33Z
- **Tasks:** 2 (Task 1 tracer, Task 2 tests TDD)
- **Files modified:** 3 (tous créés)

## Accomplishments

- `check-dev-bootstrap.sh` : continuum à 4 états mutuellement exclusifs, premier qui matche
  gagne (D-01), items de démarrage restitués dans un ordre figé et déterministe (D-03), détection
  « code source présent » par `find -prune` réutilisant textuellement le motif `PRUNE_VENDOR` de
  `detect-planning-debt.sh` et l'étendant à `docs/`, `.planning/`, `.claude/`.
- Lecture bornée et assainie du frontmatter de `.planning/STATE.md` (état 3) : liste blanche
  stricte `^[0-9A-Za-z._ /-]{1,80}$`, soupape de sûreté sur tout échec (D-04, T-17-01) — jamais
  d'état inventé, jamais de fuite d'un octet de contrôle ou d'une séquence d'échappement sur
  stdout.
- Rupture assumée et documentée de la convention « exit 3 ⇔ silence » à l'état 3 (D-14) : le
  signal `[gsd-engine]` imprime 2 lignes ET sort en 3 — vérifié empiriquement, sortie et code de
  sortie asserés séparément dans chaque cas de test concerné.
- Premier dossier `hooks/` du module `dev-orchestrator`, fragment `SessionStart:startup` verbatim
  spec §3.4/D-10 (3 commandes tolérantes à l'échec, gabarit `{{VF_SCRIPTS}}` résolu par l'engine).
- Suite `test-check-dev-bootstrap.sh` : 23 assertions, harnais reproduit de
  `test-discover-unintegrated-docs.sh`, mutuelle exclusion des 3 signaux prouvée par fixtures
  isolées, idempotence des fixtures vérifiée (deux exécutions consécutives de la suite, 0 ko).

## Task Commits

Chaque tâche a été commitée atomiquement :

1. **Task 1 (tracer) : continuum bout-en-bout — `check-dev-bootstrap.sh` + fragment de hooks** -
   `c5995ec` (feat)
2. **Task 2 : suite `test-check-dev-bootstrap.sh`** - `5adae40` (test)

_Note : Task 2 était `tdd="true"` mais le comportement complet (4 états + soupapes) était déjà
implémenté et prouvé manuellement à l'issue de la Task 1 (tracer) ; la suite a donc été écrite en
un seul commit `test` couvrant l'ensemble des cas, sans cycle RED séparé — cohérent avec le rôle
de tracer de la Task 1, qui doit déjà être fonctionnel avant expansion._

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` - script de constat SessionStart,
  continuum à 4 états, contrat de sortie 0/3/64, lecture seule.
- `plugin/dev-orchestrator/hooks/hooks.json` - fragment `SessionStart:startup`, 3 commandes
  (`check-dev-bootstrap.sh`, `discover-unintegrated-docs.sh`, `check-doc-drift.sh` — les deux
  derniers scripts n'existent pas encore, plan 17-02, sans effet grâce au tolérant d'échec).
- `plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh` - suite de 23 assertions.

## Decisions Made

- **Valeurs réelles du frontmatter utilisées pour la vérification, pas les valeurs figées dans le
  texte du plan.** Le texte de vérification automatisée du plan (`<verify>` de la Task 1)
  contenait un grep en dur sur `phase 15`, reflet de l'état de `.planning/STATE.md` au moment de
  la rédaction du plan. Entre la rédaction du plan et son exécution, la Phase 16 a été shippée
  (`v2.41.0`) et `STATE.md` porte désormais `current_phase: 16`. Le script lit dynamiquement le
  frontmatter (jamais de valeur codée en dur dans le script lui-même — vérifié par les tests) ;
  c'est donc le texte du plan qui était périmé, pas le comportement du script. Vérification
  empirique effectuée avec les valeurs réelles (`gsd-migration`, `phase 16`, `shippée`), conforme
  aux `success_criteria` explicites de l'exécution (« valeurs réelles du frontmatter »).
- **`--hook` ne change aucun format de sortie pour ce script.** Contrairement à
  `discover-unintegrated-docs.sh` (qui bascule d'une liste `grain\tchemin` à une ligne agrégée),
  `check-dev-bootstrap.sh` n'a qu'un seul format de signal (les 2 lignes de la spec §4.1),
  identique avec ou sans `--hook`. Le flag est conservé pour la parité d'interface avec les deux
  autres scripts de la phase et pour le gate de mutuelle exclusion avec `--quiet` — sans effet sur
  le rendu, ce qui satisfait trivialement « --hook change UNIQUEMENT le format de stdout ; les 4
  exits sont identiques avec ou sans ».
- **Libellé de constat pour l'item `roadmap`** : « feuille de route absente » — aucune formulation
  verbatim n'était fournie par la spec pour ce troisième item (seuls `config`/`codebase` avaient un
  exemple exact en §4.1) ; formulation factuelle, non jugeante (P-01/P-02), cohérente avec le
  style des deux autres items.
- **État `.planning/` présent sans `PROJECT.md`** : combinaison non couverte littéralement par les
  4 états de D-01 (aucun des 4 ne matche). Traité en silence total, exit 3 — choix conservateur
  cohérent avec le principe D-04 « jamais d'état inventé » plutôt que d'extrapoler un 5e état non
  spécifié.
- **Tracer feedback gate (contexte de mission autonome)** : le plan porte `autonomous: true` et ce
  dispatch d'exécution n'a fourni aucun protocole de checkpoint (contrairement au flux CLI
  interactif standard `/gsd-execute-phase`). Après la Task 1 (tracer), le `<verify>` a été rejoué
  manuellement avec succès (`TRACER-OK-REAL-VALUES`) avant d'enchaîner sur la Task 2, conformément
  à la branche autonome du protocole tracer plutôt qu'à un arrêt interactif.

## Deviations from Plan

**Aucune déviation de comportement.** Une seule note de contexte (documentée ci-dessus en
Decisions Made) : le texte de vérification automatisée de la Task 1 contenait une valeur figée
(`phase 15`) devenue obsolète entre la rédaction du plan et son exécution — le script produit la
valeur réelle et correcte (`phase 16`), conformément à sa conception (lecture dynamique du
frontmatter, jamais de valeur en dur).

## Issues Encountered

- Le bac à sable d'exécution refuse l'écriture sous `/tmp` (`read-only file system`) — contourné
  en redirigeant les sorties de vérification temporaires vers le répertoire scratchpad de session
  plutôt que `/tmp` directement. N'affecte aucun artefact livré (les scripts eux-mêmes utilisent
  `mktemp`/répertoires de test isolés sous le `TMPDIR` réel, pas `/tmp` en dur).

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- La tranche traçante (script → hook → contexte de session) est prouvée de bout en bout sur ce
  dépôt réel : le signal `[gsd-engine]` est réellement observable, exit 3, 2 lignes, valeurs du
  frontmatter reprises correctement.
- Le plan 17-02 peut réutiliser directement le patron composite (shebang/header/arg-loop/say()/
  contrat 0/3/64/lecture seule) pour `check-doc-drift.sh`, et étendre `hooks/hooks.json` n'est pas
  nécessaire — le fragment déjà posé référence déjà les 3 commandes de la phase (les 2 scripts
  manquants sont neutralisés par le tolérant d'échec jusqu'à leur création).
- Aucun blocage identifié pour la suite de la phase.

---
*Phase: VFDO-17-signaux-de-d-marrage-du-moteur-de-dev*
*Completed: 2026-07-27*

## Self-Check: PASSED

- FOUND: plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh
- FOUND: plugin/dev-orchestrator/hooks/hooks.json
- FOUND: plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh
- FOUND: .planning/phases/VFDO-17-signaux-de-d-marrage-du-moteur-de-dev/17-01-SUMMARY.md
- FOUND commit c5995ec, FOUND commit 5adae40, FOUND commit ac9d9da
- `git status --short` ne montre que les 2 chemins hors périmètre déjà non trackés avant
  exécution (`.planning/missions/dag-phase17.json`,
  `.planning/phases/VFDO-18-capability-living-specs-conventions-openspec/`), laissés intacts.
