---
phase: quick-260810-fh3
plan: 01
subsystem: dev-tooling
tags: [bash, claude-plugin-cli, adr-054, design-orchestrator, vibeflow-update]

# Dependency graph
requires: []
provides:
  - "ensure-design-deps.sh — bootstrap autonome présence+activation des 4 plugins de la chaîne design"
  - "Câblage engine (hook post-install nommé, best-effort, double garde -f) dans vibeflow-update.sh"
  - "Câblage agent (section Premier contact) dans design-orchestrator/AGENT.md"
  - "Contrat de non-silence : flag --quiet (routine muette, anomalies toujours émises) et hook engine qui ne redirige plus stderr"
  - "9 cas de test T9..T9g dans test-design-orchestrator.sh (idempotence, scope, D-02, dégradation, D-04, câblage double, non-silence)"
  - "design-toolchain.md et README.md machine-vérifiés, module design-orchestrator bumpé v1.5.0"
affects: [design-orchestrator, vibeflow-update-engine]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 10305
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Cascade de détection sans verdict sans preuve : source structurée (claude plugin list --json, garde ADR-054 stub python3) en primaire, machine à états awk sur sortie décorée en repli, état indéterminé + étapes manuelles si aucune source"
    - "Duplication délibérée de forme (D-04) entre bootstraps de modules voisins plutôt que source croisée — même précédent que ensure-deps.sh / check-gsd-engine.sh"
    - "Table de configuration littérale jamais dérivée de l'environnement, avec note de non-divergence explicite vers sa jumelle documentaire"

key-files:
  created:
    - plugin/design-orchestrator/scripts/ensure-design-deps.sh
  modified:
    - plugin/_internal/vibeflow-update.sh
    - plugin/design-orchestrator/AGENT.md
    - plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
    - plugin/design-orchestrator/references/design-toolchain.md
    - plugin/design-orchestrator/README.md
    - plugin/design-orchestrator/CHANGELOG.md
    - plugin/design-orchestrator/VERSION
    - plugin/design-orchestrator/module.json

key-decisions:
  - "claude plugin marketplace add porte --scope au même titre qu'install/enable — corrige une contradiction entre le texte <action> du plan (marketplace add sans scope) et son <done> (« toutes les commandes scopées, dont la ligne d'ajout de marketplace ») ; la CLI réelle supporte --scope sur marketplace add, vérifié via --help"
  - "FORCE (dry-run uniquement) bascule tous les plugins sur la branche 'absent' pour rendre observables les 5 commandes scopées, même sur une machine déjà équipée — même sémantique que VF_ENSURE_FORCE du bootstrap de dev"
  - "installed_plugins.json écarté comme source : aucun champ enabled, c'est l'origine du trou fermé par ce plan"
  - "Contrat de non-silence (revue d'orchestration, post-exécution) : le hook appelait le script avec >/dev/null 2>&1 alors que tout sort sur stderr — plugin manquant et étapes manuelles disparaissaient, la dégradation silencieuse se rejouait un cran plus haut. Correction : helpers scindés log() routine / notice() anomalie, drapeau ANOMALY qui décide si le résumé traverse --quiet, hook en --quiet sans 2>&1"

patterns-established:
  - "Pattern de bootstrap module autonome (D-04) : jamais de source croisée entre modules, duplication de forme assumée et documentée en en-tête"

requirements-completed: [D-01, D-02, D-03, D-04]

coverage:
  - id: D1
    description: "ensure-design-deps.sh détecte présence ET activation des 4 plugins de la chaîne design, idempotent, toujours exit 0 sauf VF_SCOPE invalide, dégrade sur étapes manuelles si claude est absent"
    requirement: D-01
    verification:
      - kind: integration
        ref: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh#T9 idempotence"
        status: pass
      - kind: integration
        ref: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh#T9b scope"
        status: pass
      - kind: integration
        ref: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh#T9d dégradation"
        status: pass
    human_judgment: false
  - id: D2
    description: "Un plugin installé mais désactivé est rapporté manquant (enable scopé, jamais install nu) ; un plugin actif sur au moins un marketplace parmi plusieurs entrées du même nom est rapporté présent sans geste (cas réel frontend-design)"
    requirement: D-02
    verification:
      - kind: integration
        ref: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh#T9c sous-cas 1"
        status: pass
      - kind: integration
        ref: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh#T9c sous-cas 2"
        status: pass
    human_judgment: false
  - id: D3
    description: "Câblage double best-effort : hook post-install nommé (vibeflow-update.sh) et premier contact (AGENT.md), aucun des deux ne peut faire échouer/bloquer respectivement l'install d'un module ou un geste design"
    requirement: D-03
    verification:
      - kind: integration
        ref: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh#T9f câblage double"
        status: pass
      - kind: integration
        ref: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh#T9g non-silence (3 asserts)"
        status: pass
    human_judgment: false
  - id: D4
    description: "ensure-design-deps.sh n'a aucune dépendance d'exécution vers dev-orchestrator ; module.json déclare toujours exactement ['conductor']"
    requirement: D-04
    verification:
      - kind: unit
        ref: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh#T9e autonomie"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-08-10
status: complete
---

# Quick Task 260810-fh3: Bootstrap autonome présence+activation de la chaîne d'outils design

**`ensure-design-deps.sh` ferme le trou enabled/disabled de la chaîne design : détection structurée (`claude plugin list --json`, garde ADR-054), réactivation scopée plutôt qu'install nu, câblage double engine+agent best-effort, module `design-orchestrator` en v1.5.0.**

## Performance

- **Duration:** ~50 min
- **Completed:** 2026-08-10T10:09:25Z
- **Tasks:** 3/3
- **Files modified:** 9 (1 créé, 8 modifiés)

## Accomplishments

- `ensure-design-deps.sh` : cascade de détection sans verdict sans preuve (JSON structuré en
  primaire, awk sur sortie décorée en repli, indéterminé + étapes manuelles si `claude` est
  absent), règle « au moins une entrée active suffit », validation stricte de l'identifiant avant
  tout passage en argument (T-Q-01), idempotent, toujours `exit 0` sauf `VF_SCOPE` invalide.
- Câblage double best-effort : troisième hook nommé dans `vibeflow-update.sh` (double garde `-f`,
  branche `else`) + section « Premier contact — chaîne d'outils (best-effort) » dans `AGENT.md`
  avec le garde-fou d'Iron Law explicite (jamais restituer les noms de plugins bruts).
- 6 cas de test T9..T9f ajoutés à la suite existante (aucun nouveau fichier, compteur racine
  inchangé à 52) : idempotence, scope, le cas de la tâche (D-02, deux sous-cas), dégradation,
  autonomie D-04, câblage double. Discriminance de T9c prouvée par mutation réelle (revert à une
  simple présence de nom → le sous-cas 2 rougit pour la bonne raison, puis restauré).
- `design-toolchain.md` et `README.md` machine-vérifiés (renvoi vers le script, contrat en
  3 points, note de non-divergence), module `design-orchestrator` en v1.5.0.

## Task Commits

Each task was committed atomically:

1. **Task 1: ensure-design-deps.sh — la chaîne complète, prouvée de bout en bout en dry-run** - `cd1f748` (feat)
2. **Task 2: câblage double (engine + agent) et les 6 cas de test** - `c184174` (feat)
3. **Task 3: doc de la chaîne d'outils machine-vérifiée + hygiène de module (v1.5.0)** - `8d3da9c` (docs)
4. **Correctif de revue : non-silence (`--quiet` + hook qui n'avale plus stderr)** - `e9b3650` (fix)

_Note : `c184174` inclut aussi un fix ciblé sur `ensure-design-deps.sh` (voir Déviations)._

### Le correctif de revue (`e9b3650`)

Défaut relevé par l'orchestrateur après retour de l'exécuteur, sur le résultat livré et non sur
le plan : le hook post-install appelait `ensure-design-deps.sh` avec `>/dev/null 2>&1`, alors que
**tout** le script parle sur stderr. Une install où les 4 plugins manquent et où l'auto-install
échoue (CLI `claude` absente, réseau, marketplace injoignable) n'aurait produit **aucune ligne** —
la dégradation silencieuse que ce module vient fermer, déplacée d'un cran.

Correction en trois points, tous verrouillés par T9g :
1. `log()` (routine, supprimée par `--quiet`) séparée de `notice()` (anomalie, traverse toujours),
   `err()` inchangée. Les étapes manuelles et les gestes réellement exécutés passent en `notice`.
2. Drapeau `ANOMALY`, armé dès qu'un plugin n'était pas déjà actif — y compris quand le geste
   RÉUSSIT, parce qu'une install qui pose des plugins dans le dos de l'utilisateur doit rester
   visible. C'est lui qui décide si le résumé traverse `--quiet`.
3. Hook engine en `--quiet` **sans** `2>&1`, avec le motif écrit sur place pour qu'une future main
   ne « nettoie » pas la sortie en réintroduisant la redirection.

Contre-épreuve exécutée : deux mutations (retour de `notice` à `log` sur le résumé et l'annonce
d'anomalie ; retour du hook à `>/dev/null 2>&1`) font rougir les asserts 2/3 et 3/3 chacun pour son
propre motif, puis restauration et re-confirmation du vert.

## Files Created/Modified

- `plugin/design-orchestrator/scripts/ensure-design-deps.sh` - Bootstrap autonome présence+activation, nouveau fichier
- `plugin/_internal/vibeflow-update.sh` - Troisième hook post-install nommé, strictement symétrique de ses deux jumeaux
- `plugin/design-orchestrator/AGENT.md` - Section « Premier contact — chaîne d'outils (best-effort) » (193L, ≤250 ADR-029)
- `plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` - Bloc T9..T9f (6 cas), bandeau de commentaires mis à jour
- `plugin/design-orchestrator/references/design-toolchain.md` - §Vérification de présence machine-vérifiée + note de non-divergence
- `plugin/design-orchestrator/README.md` - Table Reference, ligne suite de tests, bullet Limites reformulée, version v1.5.0
- `plugin/design-orchestrator/CHANGELOG.md` - Entrée v1.5.0
- `plugin/design-orchestrator/VERSION` + `plugin/design-orchestrator/module.json` - v1.4.2 → v1.5.0

## Decisions Made

- **`claude plugin marketplace add` porte `--scope`** au même titre que `install`/`enable` : le
  texte `<action>` du plan montrait la commande sans scope, mais son `<done>` exigeait « toutes les
  commandes scopées, dont la ligne d'ajout de marketplace ». Vérifié que la CLI réelle supporte
  `--scope` sur `marketplace add` (`claude plugin marketplace add --help`) avant de trancher en
  faveur du `<done>` — le contrat le plus contraignant et le plus vérifiable machine.
- **`FORCE` (dry-run uniquement) bascule tous les plugins sur la branche `absent`** plutôt que de
  re-dériver un état forcé par plugin : reproduit fidèlement la sémantique `VF_ENSURE_FORCE` du
  bootstrap de dev (court-circuite le skip « déjà présent », jamais d'effet en réel) et rend
  observables les 5 commandes scopées même sur une machine où les 4 plugins sont déjà actifs.
- **`installed_plugins.json` explicitement écarté** comme source de repli : aucun champ `enabled`
  — c'est l'origine même du trou fermé par ce plan (découverte 2 du PLAN).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `claude plugin marketplace add` sans `--scope` contredisait le `<done>` du plan**
- **Found during:** Task 1 (vérification du script contre le `<verify>` puis relecture du `<done>`)
- **Issue:** L'implémentation initiale suivait le texte `<action>` littéral (marketplace add sans
  `--scope`), mais le `<done>` de la même tâche affirme "toutes les commandes scopées, dont la
  ligne d'ajout de marketplace pbakaus/impeccable" — contradiction interne au plan.
- **Fix:** Ajout de `--scope "$SCOPE"` à l'appel `claude plugin marketplace add`, après vérification
  que la CLI réelle supporte ce flag (`claude plugin marketplace add --help` confirme
  `--scope <scope>`). Toutes les commandes loguées en dry-run forcé portent désormais `--scope`.
- **Files modified:** plugin/design-orchestrator/scripts/ensure-design-deps.sh
- **Verification:** Re-exécution complète du `<verify>` de Task 1 (4 assertions) + idempotence
  (2 runs dry-run identiques) + T9b (toutes les commandes loguées portent `--scope project`).
- **Committed in:** c184174 (Task 2 commit, groupé avec le câblage double)

---

**Total deviations:** 1 auto-fixed (Rule 1 - contradiction interne du plan entre `<action>` et `<done>`)
**Impact on plan:** Correction nécessaire pour honorer le `<done>` machine-vérifiable de Task 1. Pas de dérive de périmètre — le comportement observable (commandes scopées) est celui explicitement attendu.

## Issues Encountered

None.

## Known Stubs

None — aucun stub, aucune donnée factice.

## Threat Flags

None — la surface introduite (appels réseau `claude plugin install/enable/marketplace add`
non-interactifs déclenchés par un hook post-install) était déjà anticipée et disposée dans le
threat register du PLAN (T-Q-01..T-Q-05, tous `mitigate` ou `accept` avec borne explicite), pas
une découverte hors périmètre.

## TDD Gate Compliance

N/A — plan `type: execute` (pas `type: tdd`), aucune tâche `tdd="true"` dans le PLAN.

## User Setup Required

None - no external service configuration required.

## Self-Check: PASSED

Tous les 9 fichiers cités (Files Created/Modified) trouvés sur disque. Les 3 hashes de commit
(`cd1f748`, `c184174`, `8d3da9c`) trouvés dans `git log --oneline --all`.

## Next Phase Readiness

- `ensure-design-deps.sh` est posé, testé et câblé — prêt à atterrir chez l'utilisateur au
  prochain `vibeflow-update.sh install`/`update` du module `design-orchestrator` (copié à plat
  dans `$TARGET_ROOT/scripts/` par `copy_module_scripts()`).
- Release racine (bump `VERSION`/`plugin.json`/`marketplace.json`, tag annoté, release GitHub)
  volontairement hors périmètre de cette tâche — geste humain distinct, comme demandé.
- Aucun blocker.

---
*Phase: quick-260810-fh3*
*Completed: 2026-08-10*
