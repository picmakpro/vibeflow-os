---
phase: VFDO-19-migration-du-moteur-gsd-pilotee-par-vf-update
plan: 03
subsystem: infra
tags: [bash, vf-update, adr, release-meta, gsd-core, check-version-sync]

# Dependency graph
requires:
  - phase: VFDO-19-01
    provides: "check-gsd-engine.sh (gate de constat à 3 états, exits 0/2/3, signaux [gsd-migrate]/[gsd-leftover])"
  - phase: VFDO-19-02
    provides: "ensure-deps.sh --migrate-engine (chaîne install npx puis patch_gsd_executor_mcp dans le même run)"
provides:
  - "vf-update/SKILL.md : diagnostic à deux volets — la sonde moteur est consultée AVANT le stop sur plugin à jour"
  - "ligne de confirmation moteur indépendante dans l'AskUserQuestion existante, refus sans effet de bord (ADR-031)"
  - "docs/ADR.md ADR-058 : le moteur GSD entre dans le périmètre de /vf-update"
  - "dev-orchestrator v2.7.0, conductor v1.16.0 (triade + CHANGELOG)"
affects: [vf-update-skill, dev-orchestrator-module, conductor-module, release-humaine]

tech-stack:
  added: []
  patterns:
    - "Sonde cross-module par présence de fichier avec cascade <S> dédiée (<S-moteur>), 3e position pointant vers le module réel (dev-orchestrator) et jamais celui du skill appelant (conductor) — D-00"
    - "Confirmation ADR-031 en ligne indépendante dans un AskUserQuestion existant, plutôt qu'un second prompt"
    - "Différé de release nommé dans le SUMMARY plutôt que corrigé hors du commit de release humain (même patron que Phases 13/17)"

key-files:
  created: []
  modified:
    - plugin/conductor/skills/vf-update/SKILL.md
    - docs/ADR.md
    - plugin/dev-orchestrator/VERSION
    - plugin/dev-orchestrator/module.json
    - plugin/dev-orchestrator/README.md
    - plugin/dev-orchestrator/CHANGELOG.md
    - plugin/conductor/VERSION
    - plugin/conductor/module.json
    - plugin/conductor/README.md
    - plugin/conductor/CHANGELOG.md

key-decisions:
  - "Le point de couture est un ORDRE, pas un texte : la sonde check-gsd-engine.sh est consultée en ligne 30 du SKILL.md, le stop combiné (« Arrêt combiné ») en ligne 63 — vérifié par comparaison de deux grep -n"
  - "Phrase « hors périmètre de ce skill » supprimée mot pour mot (grep -c → 0) plutôt que reformulée en gardant la même chaîne — pour satisfaire l'acceptance criteria littéral"
  - "Superpowers reste hors périmètre, formulé sans réutiliser la chaîne interdite, pour ne pas re-matcher le grep de non-régression"

requirements-completed: [SC2, SC7]

coverage:
  - id: D1
    description: "Diagnostic à deux volets : la sonde check-gsd-engine.sh est consultée avant le stop sur update_available=false, un poste plugin-à-jour/moteur-legacy ne s'arrête plus sur « VibeFlow est à jour » seul"
    requirement: SC2
    verification:
      - kind: other
        ref: "grep -n 'check-gsd-engine.sh' (ligne 30) < grep -n 'Arrêt combiné' (ligne 63) dans plugin/conductor/skills/vf-update/SKILL.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ligne de confirmation moteur indépendante de la ligne plugin/modules, refus sans effet de bord, aucun flag nouveau créé"
    requirement: SC2
    verification:
      - kind: other
        ref: "grep -c -- '--engine-only' SKILL.md == 0 ; grep textuel étape 3 sur l'indépendance et l'absence d'effet de bord"
        status: pass
    human_judgment: false
  - id: D3
    description: "ADR-058 posé (index + section complète) et référencé depuis le §Garde-fous réécrit"
    requirement: SC7
    verification:
      - kind: other
        ref: "grep -c 'ADR-058' docs/ADR.md == 2 ; grep -c 'ADR-058' SKILL.md >= 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "Triades de release cohérentes (dev-orchestrator v2.7.0, conductor v1.16.0), gouvernance tenue (check-agents --strict, suites conductor vertes)"
    requirement: SC7
    verification:
      - kind: unit
        ref: "bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/dev-orchestrator/agents (exit 0) + 11 suites conductor (0 KO)"
        status: pass
    human_judgment: false
  - id: D5
    description: "check-version-sync.sh rouge UNIQUEMENT sur le compteur de suites des 2 README racine (41 vs 42 réel), reste-à-faire nommé et non corrigé"
    requirement: SC7
    verification:
      - kind: other
        ref: "bash scripts/check-version-sync.sh — 2 lignes ✗, toutes deux mentionnant 'suites'"
        status: pass
    human_judgment: false

# Metrics
duration: ~40min
completed: 2026-07-28
status: complete
---

# Phase VFDO-19 Plan 03: Branchement `/vf-update` sur le moteur GSD + ADR-058 + release-meta Summary

**L'étape 1 de `vf-update/SKILL.md` consulte désormais la sonde `check-gsd-engine.sh` AVANT tout arrêt sur « plugin à jour » — un poste plugin-à-jour/moteur-legacy ne s'arrête plus net et voit la migration proposée comme une ligne indépendante de confirmation ; ADR-058 acte le changement de doctrine ; `dev-orchestrator` v2.7.0 et `conductor` v1.16.0.**

## Performance

- **Duration:** ~40 min
- **Tasks:** 3/3 complétées
- **Files modified:** 10 (les 10 du périmètre exact du plan) + `.planning/STATE.md` (édité à la main, hors triade release)

## Accomplissements

- **Diagnostic à deux volets** : le volet plugin reste inchangé (`check-plugin-update.sh --print`),
  le volet moteur (`check-gsd-engine.sh --quiet` via `<S-moteur>`) s'exécute désormais AVANT le stop
  sur `update_available = false`. Le point de couture de la phase est vérifié par comparaison de
  deux `grep -n` : la première mention de `check-gsd-engine.sh` (ligne 30) précède la ligne du stop
  combiné « Arrêt combiné » (ligne 63).
- **Trois branches exactement, écrites noir sur blanc** : script introuvable → silence total ; exit
  `0` (legacy) → ligne moteur composée, flux continue même si le plugin est à jour ; exit `3`
  (INDÉTERMINÉ) → affiche le sous-cas reliquat `[gsd-leftover]` sans jamais proposer de migration,
  ou ne dit rien si le gate n'a rien imprimé. Erreur d'usage (exit `2`) traitée comme une absence.
- **Cascade `<S-moteur>`** documentée : mêmes deux premières positions que `<S>`, 3e position
  `${CLAUDE_PLUGIN_ROOT}/dev-orchestrator/scripts/` (pas `conductor/scripts/`) — conséquence
  mécanique de D-00 (conductor mandatory, dev-orchestrator ne l'est pas).
- **Étape 3** : ligne de confirmation moteur ajoutée à l'`AskUserQuestion` existante, acceptable ou
  refusable indépendamment de la ligne plugin et de la ligne modules, refus sans effet de bord ni
  relance. Bornes des deux flags existants explicitées (`--check` affiche sans demander,
  `--modules-only` ne propose pas la migration moteur) — aucun flag nouveau créé.
- **Étape 4** : sous-étape « couche moteur » invoquant `ensure-deps.sh --migrate-engine`, exécutée
  même si la couche plugin a échoué, sans jamais invoquer l'installeur amont directement (Iron Law
  2). Étape 5 complétée d'un rappel : une migration moteur pose de nouveaux agents/skills, pris en
  compte au prochain démarrage seulement.
- **§Garde-fous réécrit** : la phrase « hors périmètre de ce skill » a disparu (`grep -c` → `0`),
  remplacée par une frontière couvrant plugin + modules + état du moteur GSD (détecté et proposé,
  jamais installé sans accord), renvoyant vers ADR-058. Superpowers reste hors périmètre.
- **ADR-058** posé dans `docs/ADR.md` : ligne d'index après ADR-057 + section complète (Date,
  Statut, Décideur, Problème, 4 options dont 3 rejetées, Décision en 6 points citant ADR-031 et
  l'interdiction de classer sur les numéros, Conséquences avec risque explicite, Code Impacté,
  Rules Associées citant ADR-031 et ADR-055 §3).
- **Release-meta** : `dev-orchestrator` v2.6.0 → v2.7.0 (triade + CHANGELOG daté), `conductor`
  v1.15.0 → v1.16.0 (triade + CHANGELOG daté). Aucun fichier racine touché, aucun tag créé.

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Task 1 : `vf-update/SKILL.md` — diagnostic à deux volets** - `e54bd7d` (feat)
2. **Task 2 : ADR-058 — le moteur GSD entre dans le périmètre de `/vf-update`** - `f29b8de` (docs)
3. **Task 3 : release-meta dev-orchestrator v2.7.0 + conductor v1.16.0** - `63e0e2b` (chore)

**Plan metadata :** (commit de clôture de ce SUMMARY/STATE)

## Files Created/Modified

- `plugin/conductor/skills/vf-update/SKILL.md` — diagnostic à deux volets, ligne de confirmation
  moteur, sous-étape 4c, §Garde-fous réécrit (82 → 131 lignes, ≤ 500, ADR-029 respecté)
- `docs/ADR.md` — ADR-058 (ligne d'index + section complète, 853 → 927 lignes)
- `plugin/dev-orchestrator/{VERSION,module.json,README.md,CHANGELOG.md}` — v2.7.0
- `plugin/conductor/{VERSION,module.json,README.md,CHANGELOG.md}` — v1.16.0
- `.planning/STATE.md` — édité à la main (voir contrainte ci-dessous), `completed_plans` 36 → 37,
  les 4 autres compteurs inchangés

## Decisions Made

- Le §Garde-fous supprime la chaîne exacte « hors périmètre de ce skill » plutôt que de la
  reformuler en la gardant : l'acceptance criteria de la Task 1 exige `grep -c 'hors périmètre de
  ce skill' == 0`, donc la formulation Superpowers évite délibérément cette même chaîne (« Superpowers
  reste hors périmètre » sans le suffixe « de ce skill »).
- `<S-moteur>` introduit comme symbole documenté distinct de `<S>` plutôt que de réutiliser `<S>`
  avec une exception implicite en 3e position — plus explicite pour un lecteur futur, sans changer
  le comportement (mêmes deux premières positions, seule la 3e diffère).
- Frontmatter : la clause moteur ajoutée dans `description` s'insère entre la phrase existante
  « sous validation humaine. » et les trois exclusions `✘` — vérifié par `git diff` que les trois
  exclusions et la phrase finale d'invocabilité n'apparaissent dans aucun hunk (donc inchangées).

## Deviations from Plan

None - plan exécuté tel qu'écrit, aucune règle de déviation déclenchée. La seule adaptation
(introduction du symbole `<S-moteur>` plutôt que réutiliser `<S>` directement) est une clarification
documentaire sans effet comportemental, listée ci-dessus par transparence plutôt que comme
déviation au sens des règles 1-3.

## Issues Encountered

None.

## User Setup Required

None - aucune configuration de service externe requise.

## Known Stubs

Aucun.

## Threat Flags

Aucun — la surface de sécurité est celle déjà cadrée par le `<threat_model>` du plan
(T-19-03-01 à T-19-03-06), aucune surface nouvelle non couverte n'a été introduite.

## Sortie complète de `scripts/check-version-sync.sh`

```
[check-version-sync] ✓ plugin.json 2.42.0
[check-version-sync] ✓ marketplace.json 2.42.0
[check-version-sync] ✓ README.md badge version 2.42.0
[check-version-sync] ✓ README.fr.md badge version 2.42.0
[check-version-sync] ✓ README.md badge modules 17
[check-version-sync] ✓ README.fr.md badge modules 17
[check-version-sync] ✓ README.md texte 17 modules
[check-version-sync] ✓ README.fr.md texte 17 modules
[check-version-sync] ✓ triade par module : 17 modules VERSION ↔ module.json alignés
[check-version-sync] ✓ README.md historique en tête v2.42.0
[check-version-sync] ✓ README.fr.md historique en tête v2.42.0
[check-version-sync] ✓ en-tête Version des README de modules : 17 déclarés, tous alignés
[check-version-sync] ✗ README.md : '41 suites' ≠ réel=42 (find */tests/test-*.sh)
[check-version-sync] ✗ README.fr.md : '41 suites' ≠ réel=42 (find */tests/test-*.sh)
[check-version-sync] dérive détectée — synchroniser AVANT release (canon = VERSION racine).
EXIT=1
```

**Reste-à-faire NOMMÉ, explicitement non corrigé ici** : le compteur « N suites » des deux README
racine (`README.md`, `README.fr.md`) doit passer de **41 à 42**, la suite créée en 19-01
(`test-check-gsd-engine.sh`) portant le total réel à 42 (`find plugin scripts -type f -path
'*/tests/test-*.sh' | wc -l` → `42`). Corriger ce compteur appartient au **commit de release
humain** (avec le bump `VERSION` racine, `plugin.json`, `marketplace.json`, le tag annoté et la
release GitHub) — exactement le même patron que les Phases 13 et 17. Le corriger dans ce plan
aurait signifié toucher les README racine, ce que P-01/P-02 interdisent explicitement. Tous les
autres contrôles (triades des 2 modules, en-têtes `**Version**` des README de modules, badges,
compteur de modules, historique en tête) sont **verts**.

## Résultat de `check-agents.sh --strict`

```
bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/dev-orchestrator/agents
  ⚠ vf-auditer.md : aucun skill câblé (pré-existant)
  ⚠ vf-coder.md : aucun skill câblé (pré-existant)
  ⚠ vf-dev-manager.md : aucun skill câblé (pré-existant)
  ⚠ vf-dev-manager.md : tools — 3 noms d'agent non résolus (vf-test-orchestrator, vf-crafter, vf-design-judge — pré-existant)
  ⚠ vf-reviewer.md : aucun skill câblé (pré-existant)
[check-agents] 0 fichier(s) agent tiers non linté(s) · 33 entrée(s) d'allowlist tierce(s) résolue(s) (préfixe(s) : gsd-)
[check-agents] ✓ agents conformes (natif + charte VibeFlow) · 7 warning(s)
EXIT=0
```

Les 7 warnings sont pré-existants (aucun fichier de `plugin/dev-orchestrator/agents/` n'a été
modifié par ce plan) — exit 0 conforme à l'acceptance criteria.

## Suites du module `conductor` rejouées

| Suite | Résultat |
|---|---|
| `test-check-agents.sh` | 58 OK · 0 KO |
| `test-check-debug-research.sh` | 14 OK · 0 KO |
| `test-check-legacy.sh` | 8 PASS · 0 FAIL |
| `test-check-overlaps.sh` | 16 OK · 0 KO |
| `test-conductor.sh` | 12 passés · 0 échoués |
| `test-dag.sh` | 36 PASS · 0 FAIL |
| `test-doc-and-commands.sh` | 17 PASS · 0 FAIL |
| `test-driver-lock.sh` | 26 PASS · 0 FAIL |
| `test-vf-new-lab.sh` | 21 PASS · 0 FAIL |
| `test-vf-update.sh` | 9 OK · 0 KO |
| `skills/vf-new-lab/scripts/tests/test-proportion-capabilities.sh` | 9 passés · 0 échoués |

**11/11 suites vertes, 0 KO au total.** `test-vf-update.sh` (le seul suite touchant directement le
skill modifié via ses scripts adjacents `update-banner.sh`/`vf-update-run.sh`/`vibeflow-update.sh`)
reste vert sans modification — ce plan n'a touché que le contenu prose de `SKILL.md`, jamais les
scripts qu'il orchestre.

## Contrainte STATE.md respectée

Conformément à l'instruction de l'orchestrateur (les verbes `gsd-tools query state.*` ont régressé
les compteurs de progression deux fois sur cette même phase), `.planning/STATE.md` a été édité **à
la main**, sans passer par `gsd_run query state.*`. Seule `completed_plans` a bougé (36 → 37) ; les
4 autres compteurs (`current_phase: 19`, `total_phases: 19`, `completed_phases: 10`,
`total_plans: 53`) sont restés à leur valeur baseline attendue.

## Next Phase Readiness

Phase 19 est maintenant **3/3 plans exécutés**. SC2 (diagnostic + confirmation moteur) et SC7
(doctrine + release-meta) sont tenus pour leur périmètre. Reste réservé à validation humaine, hors
de cette phase, exactement comme aux Phases 13/17 : bump `VERSION` racine + `plugin.json` +
`marketplace.json` + synchronisation du compteur de suites (41 → 42) dans les 2 README racine, tag
annoté poussé, release GitHub, puis `scripts/check-release-tag.sh --remote` vert.

---
*Phase: VFDO-19-migration-du-moteur-gsd-pilotee-par-vf-update*
*Completed: 2026-07-28*
