---
phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des
plan: 04
subsystem: governance-tooling
tags: [check-agents, manifest, freshness, D-04, D-05, D-20, mutation-testing, ci, python, bash]

# Dependency graph
requires:
  - phase: 42-01
    provides: "Manifeste daté (check-agents-manifest.json), charger_manifeste()/charger_referentiel(), harnais mk_manifest/mk_gate_dir, T77-T82, T103 (ligne cible_absente sans mutant)"
provides:
  - "Détection de péremption du manifeste par liste (manifeste_perime(), âge vs valide_jours, DATE-FUTURE) — validité lue dans le manifeste, jamais en dur (D-02)"
  - "Option --manifest-freshness=lenient|strict (défaut lenient), validée à l'identique de --resolve-agents (rejet explicite rc=1 sur valeur inconnue)"
  - "INDÉTERMINÉ (exit 3, jeton MANIFESTE-PERIME) réservé à --manifest-freshness=strict — la CI du dépôt seule (D-04)"
  - "Rétrogradation D-05 : « outil hors du set connu » et « nom d'agent non résolu » passent en avertissement suffixé [MANIFESTE-PERIME — retrograde en avertissement, D-05] sous manifeste périmé, dans tous les contextes ; champ inconnu et model/memory/effort/permissionMode inchangés (Pitfall 3)"
  - "Helpers de mutation QUAL-01 pour ce gate (make_gate_mutant/okmut/komut, patron test-check-gate-touche.sh) — MUT-F1, MUT-F2, et MUT-D20 (mutant de la ligne cible_absente posée en 42-01, laissé à cette tâche faute de harnais plus tôt)"
  - "Les quatre appels check-agents.sh de la CI (3 étapes du job gates + Gate C du lab frais) durcis avec --manifest-freshness=strict — seul lieu où l'INDÉTERMINÉ de fraîcheur est rendu"
affects: [VFDO-42-05, VFDO-42-06]

# Actuals (#2632)
actuals:
  tokens: 9353
  tasks: 2
  commits: 2
plan_head_before: e3ba8f9

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "manifeste_perime(manifest, aujourd_hui) : fonction pure, une description par liste périmée, appelée UNE fois dans charger_referentiel (chargement paresseux inchangé — fraîcheur jamais évaluée sur cible vide)"
    - "Rétrogradation D-05 conditionnelle : erreur seulement si (strict|resolve_agents_strict) ET NOT retrograder — même régime pour les deux classes concernées, suffixe [MANIFESTE-PERIME — retrograde en avertissement, D-05] uniquement quand la péremption a réellement évité le refus"
    - "make_gate_mutant(id, age, motif, remplacement, [op]) : mutation d'UNE ligne unique dans une copie de check-agents.sh construite par mk_gate_dir (même âge/opération que le run original), valeurs par ENVIRON jamais awk -v, refus si identique (cmp) ou bash -n invalide — même discipline que test-check-gate-touche.sh"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/tests/test-check-agents.sh
    - .github/workflows/ci.yml

key-decisions:
  - "D-02/D-04/D-05 tenus tels quels : validité lue dans le manifeste (aucune valeur par défaut) ; INDÉTERMINÉ réservé à --manifest-freshness=strict (CI seule) ; seules « outil hors du set connu » et « nom d'agent non résolu » rétrogradées — champ inconnu et model/memory/effort/permissionMode/isolation restent bloquants (Pitfall 3, lecture littérale du plan)"
  - "Péremption par liste (pas une moyenne globale ni un champ top-level séparé) : manifeste_perime() itère les six listes dans l'ordre du manifeste, une description par liste en cause — DATE-FUTURE prioritaire sur le calcul d'âge pour une même liste"
  - "Issue sous option strict avec erreurs déjà présentes : l'INDÉTERMINÉ (rc 3) prime sur un rc 1 déjà imprimé — les erreurs restent affichées avant la ligne INDETERMINE (lecture littérale de FABR-02, cf. Assumptions Log du plan)"
  - "MUT-D20 posé ici (mission revise-42c), pas en 42-01 : les helpers de mutation (make_gate_mutant/okmut/komut) n'existaient pas avant cette tâche — 42-01 ne pouvait pas les présupposer"
  - "Ligne de rapport MANIFESTE-PERIME ne contient jamais ✗ (avertissement, pas un refus) ; elle précède la liste des avertissements hors --hook, et s'imprime sous --hook même sans autre avertissement (jamais silence de message)"

patterns-established:
  - "Un gate qui charge un manifeste daté expose sa fraîcheur via une fonction pure appelée UNE fois après le chargement, jamais recalculée ailleurs — les deux lignes d'affectation (perimees=..., retrograder=...) restent des cibles de mutation isolées, jamais fusionnées"
  - "La rétrogradation d'une classe d'erreur sous périmé se code comme un garde supplémentaire AUTOUR de la condition d'erreur existante (if strict and not retrograder: erreur ; else: avertissement [+suffixe si retrograder]), jamais comme un nouveau chemin parallèle"

requirements-completed: [FABR-02]

coverage:
  - id: D1
    description: "Détection de péremption par liste (âge > valide_jours ou DATE-FUTURE), bornes exactes prouvées (âge = valide_jours → frais ; +1 → périmé ; valide_jours custom)"
    requirement: FABR-02
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T85, T86"
        status: pass
    human_judgment: false
  - id: D2
    description: "INDÉTERMINÉ (exit 3, MANIFESTE-PERIME) réservé à --manifest-freshness=strict ; jamais la ligne « ✓ agents conformes » dans ce cas ; sans l'option, avertissement seul (jamais ✗, jamais exit 3/1)"
    requirement: FABR-02
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T84, T87"
        status: pass
    human_judgment: false
  - id: D3
    description: "Rétrogradation D-05 : outil hors du set connu et nom d'agent non résolu passent en avertissement suffixé sous manifeste périmé, dans tous les contextes (CLI, --resolve-agents=strict, garde d'écriture) ; champ inconnu et model/memory/effort/permissionMode restent inchangés (Pitfall 3)"
    requirement: FABR-02
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T83, T88, T89, T90"
        status: pass
    human_judgment: false
  - id: D4
    description: "Deux mutants QUAL-01 posés et tués (MUT-F1 : detection de péremption neutralisée ; MUT-F2 : rétrogradation neutralisée) + MUT-D20 (mutant de la ligne cible_absente posée en 42-01, harnais indisponible avant cette tâche)"
    requirement: FABR-02
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#MUT-F1, MUT-F2, MUT-D20"
        status: pass
    human_judgment: false
  - id: D5
    description: "Les quatre appels check-agents.sh de la CI (3 étapes du job gates + Gate C du lab frais) passent --manifest-freshness=strict — seul lieu où l'INDÉTERMINÉ de fraîcheur est rendu"
    requirement: FABR-02
    verification:
      - kind: integration
        ref: "rejeu local des 3 étapes CI (CI-REPLAY fail=0) + Gate C d'un lab frais installé depuis plugin/ (GATE-C-OK)"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-24
status: complete
---

# Phase 42 Plan 04: Fraîcheur du manifeste — INDÉTERMINÉ en CI, avertissement chez l'utilisateur Summary

**`check-agents.sh` détecte désormais la péremption de son manifeste daté par liste (âge vs `valide_jours`, DATE-FUTURE) et n'en tire que l'effet que D-04/D-05 autorisent : INDÉTERMINÉ (exit 3) sous `--manifest-freshness=strict` — réservé aux quatre appels de la CI du dépôt — et un simple avertissement partout ailleurs, avec rétrogradation des deux seules classes d'erreur fermées concernées (outil hors du set connu, nom d'agent non résolu).**

## Performance

- **Duration:** ~50 min
- **Completed:** 2026-09-24T22:04:35Z
- **Tasks:** 2 (1 tdd, 1 auto)
- **Files modified:** 3

## Accomplishments

- `manifeste_perime(manifest, aujourd_hui)` : fonction pure qui rend, dans l'ordre des six listes, une description par liste périmée (âge strictement supérieur à `valide_jours`, ou `verifie_le` postérieur à aujourd'hui — jeton `DATE-FUTURE`, non vérifiable). Aucune valeur par défaut de validité (D-02) — appelée une seule fois dans `charger_referentiel()`, donc jamais évaluée sur cible vide (contrat F13 inchangé).
- Option `--manifest-freshness=lenient|strict` (défaut `lenient`), validée exactement comme `--resolve-agents` : toute valeur hors de cet ensemble → `[check-agents] ✗ --manifest-freshness invalide '<v>' — attendu lenient|strict`, exit 1, jamais un repli muet.
- D-04 : hors `--hook`, sous manifeste périmé **et** `--manifest-freshness=strict`, le gate imprime les erreurs éventuelles puis `[check-agents] ✗ INDETERMINE — MANIFESTE-PERIME : aucun verdict rendu (D-04) — rafraichir check-agents-manifest.json puis relancer` et sort 3 — la ligne `✓ agents conformes` n'est jamais imprimée dans ce cas. Sans l'option, le manifeste périmé ne produit qu'un avertissement `[check-agents] ⚠ MANIFESTE-PERIME — …` (jamais de `✗`), imprimé avant la liste des avertissements hors `--hook`, et systématiquement sous `--hook` même sans autre avertissement.
- D-05 : dans `lint_tool_field`, « outil hors du set connu » ne devient une erreur que si `strict and not retrograder` ; « nom d'agent non résolu » sous `--resolve-agents=strict` ne devient une erreur que si `not retrograder`. Sous manifeste périmé, les deux messages portent le suffixe ` [MANIFESTE-PERIME — retrograde en avertissement, D-05]`. « champ inconnu » et les enums `model`/`memory`/`effort`/`permissionMode`/`isolation` restent inchangés (Pitfall 3 — un modèle inventé reste inventé, indépendamment de la fraîcheur de la doc).
- Harnais de mutation QUAL-01 posé pour ce gate : `make_gate_mutant`/`okmut`/`komut` (patron `scripts/tests/test-check-gate-touche.sh`, valeurs transmises par `ENVIRON` jamais `awk -v`, refus si identique à l'original ou syntaxiquement invalide). `MUT-F1` (détection neutralisée : `perimees = []`) et `MUT-F2` (rétrogradation neutralisée : `retrograder = False`) tués. `MUT-D20` (mission `revise-42c`) tue aussi le mutant de la ligne `cible_absente` posée en 42-01, dont le harnais de mutation n'existait pas encore à cette étape.
- `T83` à `T90` couvrent : la rétrogradation elle-même et son jumeau frais (T83), l'INDÉTERMINÉ sous option et son absence sans elle (T84), les bornes exactes de péremption y compris `valide_jours` personnalisé (T85), `DATE-FUTURE` sur une liste forgée dans le futur (T86), le silence total du hook sous manifeste frais et sa non-évaluation sur cible vide (T87), le régime inchangé de `model`/`memory`/`effort` sous périmé (T88), la rétrogradation sous `--resolve-agents=strict` en réutilisant le registre de T30 (T89), et le comportement de la garde d'écriture + le rejet de valeur d'option inconnue (T90).
- Les quatre appels `check-agents.sh` de la CI (trois étapes du job `gates` + Gate C du job `lab-frais`) portent désormais `--manifest-freshness=strict` — seul endroit avec la légitimité de rafraîchir le manifeste (D-04). Repérés par leur nom d'étape, jamais par un numéro de ligne ; aucune autre partie de ces étapes touchée.

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Tâche 1 (tdd) — fraîcheur du manifeste, T83-T90, MUT-F1/F2/D20** — `8c507e7` (feat)
2. **Tâche 2 (auto) — CI durcie avec --manifest-freshness=strict** — `4d69837` (ci)

_Note : suivi tel qu'écrit dans `<action>` du plan (un commit par tâche, tests+implémentation couplés pour la tâche 1 en TDD, cf. instruction explicite du plan) — SUMMARY committée séparément, comme prescrit par `<output>`._

## Files Created/Modified

- `plugin/conductor/scripts/check-agents.sh` — `manifeste_perime()`, `--manifest-freshness`, rétrogradation D-05, issue D-04
- `plugin/conductor/scripts/tests/test-check-agents.sh` — `make_gate_mutant`/`okmut`/`komut`, T83-T90, MUT-F1, MUT-F2, MUT-D20
- `.github/workflows/ci.yml` — `--manifest-freshness=strict` aux quatre appels de check-agents

## Decisions Made

- Toutes les décisions de cadrage (D-02, D-04, D-05, D-20) proviennent de `42-CONTEXT.md`, tranchées par Claude sur délégation explicite de Willy (AskUserQuestion session principale, 2026-09-23) — voir `key-decisions` en frontmatter pour le détail par décision.
- Choix d'implémentation locaux (Claude's Discretion, dans le périmètre déjà cadré par le plan) : jointure des descriptions de listes périmées par `"; "` dans la ligne de rapport ; placement de `manifeste_perime()` juste avant `charger_referentiel()` ; réutilisation du registre `$REG` de T30 pour la fixture T89 (avec `SendMessage` ajouté par anticipation de l'invariant I6, 42-05).

## Deviations from Plan

None — plan exécuté exactement comme écrit, y compris le correctif de revue MUT-D20 déjà intégré au texte de la tâche 1 (mission `revise-42c`).

## Issues Encountered

None.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- La fraîcheur du manifeste est posée de bout en bout (détection, rétrogradation, INDÉTERMINÉ en CI, quatre appels CI durcis) sur la fondation posée par 42-01 (`charger_manifeste()`/`charger_referentiel()`, harnais `mk_manifest`/`mk_gate_dir`).
- `make_gate_mutant`/`okmut`/`komut` sont désormais disponibles pour 42-05 (invariants I1/I4/I5/I6/I7, mutants MUT-I1/I4/I5/I6/I7) et 42-06 (I2/I3, découverte récursive, MUT-D1/D2/I2/I3) — le patron de mutation à un fichier unique par cas est établi et prouvé.
- Aucun blocage connu pour 42-05/42-06 : ce plan n'a touché ni `parse_token()`/`allowlist_agents()`, ni les invariants I1-I7, ni la découverte récursive.

---
*Phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des*
*Completed: 2026-09-24*
