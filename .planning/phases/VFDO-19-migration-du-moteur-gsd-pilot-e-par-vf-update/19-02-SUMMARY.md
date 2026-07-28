---
phase: VFDO-19-migration-du-moteur-gsd-pilot-e-par-vf-update
plan: 02
subsystem: infra
tags: [bash, gsd-core, mcp, adr-051, adr-031, ensure-deps, inject-mcp-tools]

requires:
  - phase: VFDO-19-01
    provides: "check-gsd-engine.sh (gate de détection à 3 états, plan parallèle disjoint)"
provides:
  - "detect_gsd_state() à 3 valeurs (absent/legacy/gsd-core) dans ensure-deps.sh, source unique dont detect_gsd() dérive"
  - "chemin --migrate-engine (+ VF_ENSURE_MIGRATE_ENGINE) qui enchaîne install npx puis patch_gsd_executor_mcp() dans le même run"
  - "message de nettoyage legacy exact (npm ls -g conditionnel) et atteignable même si l'installeur amont supprime son propre témoin VERSION pendant l'install"
  - "mode inject-mcp-tools.sh --verify (lecture seule, exits 0/1/3) branché en best-effort après --force dans patch_gsd_executor_mcp()"
affects: [VFDO-19-03, vf-update-skill, dev-orchestrator-module]

tech-stack:
  added: []
  patterns:
    - "État à 3 valeurs dérivé d'une cascade de fichiers VERSION existante, jamais un test command -v (piège n°1)"
    - "Capture d'état AVANT effet de bord irréversible, quand l'effet de bord peut supprimer le témoin qui a servi à le déclencher (D-08.3)"
    - "Mode --verify lecture-seule séparé du mode --force : dit fort, ne répare jamais (D-09/P-02)"

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/scripts/ensure-deps.sh
    - plugin/dev-orchestrator/scripts/inject-mcp-tools.sh
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
    - plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh

key-decisions:
  - "Capture de l'état legacy (GSD_LEGACY_DETECTED/GSD_LEGACY_VERSION) faite une seule fois en tête de ensure_gsd(), jamais par re-détection après l'install (D-08.3)"
  - "npm_pkg_installed_globally() est le SEUL appel npm réellement exécuté dans ce chemin (npm ls -g --depth=0, lecture seule) — uninstall/rm -rf/find -delete restent des lignes log jamais exécutées (ADR-031)"
  - "--verify ne rejoue jamais --force : branche python dédiée sans aucune écriture, verdict porté par le seul code de sortie du bloc python"

requirements-completed: [SC3, SC4, SC5, SC6]

metrics:
  duration: ~90min
  completed: 2026-07-28
status: complete
---

# Phase VFDO-19 Plan 02: Migration exécutable + vérification MCP + nettoyage exact Summary

**`ensure-deps.sh` gagne un état legacy signalé (jamais skippé) et un chemin `--migrate-engine`
chaîné à la ré-injection MCP ; `inject-mcp-tools.sh` gagne un mode `--verify` lecture-seule qui dit
fort un serveur manquant sans jamais réparer ; le message de nettoyage legacy devient exact et
survit à la suppression de son propre témoin par l'installeur amont.**

## Performance

- **Durée :** ~90 min
- **Tâches :** 3/3 complétées
- **Fichiers modifiés :** 4 (les 4 du périmètre exact du plan, aucun autre)

## Accomplissements

- `detect_gsd_state()` (nouvelle) imprime `absent`/`legacy`/`gsd-core` sur la cascade de
  dérivation existante ; `detect_gsd()` n'est plus qu'un booléen dérivé (le `||` historique a
  disparu de son corps).
- État `legacy` sans `--migrate-engine` (ni `VF_ENSURE_MIGRATE_ENGINE=1`) : message explicite
  annonçant la migration disponible, **jamais** le skip silencieux historique. Avec autorisation,
  le bloc npx existant (plafond `@opengsd/gsd-core@^1` intouché) est atteint, puis
  `patch_gsd_executor_mcp()` s'exécute dans le **même run** via l'appel déjà existant de `main()`
  (aucun second site d'appel créé — `grep -c` confirme exactement 2 occurrences : définition +
  appel).
- Message de nettoyage legacy : état capturé **avant** toute garde et tout `run_cmd` (D-08.3) —
  survit à un stub `npx` qui supprime lui-même le `VERSION` legacy pendant son exécution (T2k). Les
  2 lignes `npm uninstall -g` ne sont proposées que si `npm_pkg_installed_globally()` (seule requête
  npm réellement exécutée, lecture seule) confirme le paquet réellement présent en global ;
  arborescence vide ajoutée à la proposition, jamais exécutée.
- `inject-mcp-tools.sh --verify` : relit le `tools:` final, réutilise tels quels
  `want_tokens`/`existing`/`missing`, ne réécrit jamais rien. Exits `0` conforme / `1` serveur
  manquant (bruyant, stderr) / `3` INDÉTERMINÉ (python3 absent y compris — jamais un faux vert).
  Branché en best-effort dans `patch_gsd_executor_mcp()`, hors dry-run uniquement.

## Task Commits

1. **Task 1 : `detect_gsd_state()` 3 valeurs, fin du skip legacy, chemin `--migrate-engine`** —
   `70b5872` (feat)
2. **Task 2 : message de nettoyage exact et atteignable (capture pré-install, `npm ls -g`
   conditionnel, arborescence vide)** — `15e42c7` (fix)
3. **Task 3 : `inject-mcp-tools.sh --verify` + preuve Linux des deux suites** — `327e246` (feat)

**Plan metadata :** (à suivre — commit de clôture ci-dessous)

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/ensure-deps.sh` — `detect_gsd_state()`, `detect_gsd()` dérivé,
  `--migrate-engine`/`VF_ENSURE_MIGRATE_ENGINE`, `ensure_gsd()` à 3 branches, capture legacy
  pré-install, `npm_pkg_installed_globally()`, `log_legacy_cleanup_if_needed()` réécrite,
  `patch_gsd_executor_mcp()` enchaîne `--verify`.
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` — flag `--verify`, variable `VERIFY`,
  branche python dédiée lecture-seule, exits 0/1/3, repli python3-absent différencié en `--verify`.
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — T2g, T2h, T2i, T2j, T2k
  ajoutés ; T2d mis à jour (sémantique changée, pas contourné) ; en-tête complété.
- `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` — T10, T11 ajoutés ; en-tête
  complété.

## Compteurs de suite (preuve de non-régression)

| Suite | Avant ce plan | Après ce plan (macOS) | Après ce plan (Linux, ubuntu:24.04) |
|---|---|---|---|
| `test-dev-orchestrator.sh` | 65 OK / 0 KO / 0 SKIP | 72 OK / 0 KO / 0 SKIP | 71 OK / 0 KO / 1 SKIP (T1 index, GSD non installé dans le conteneur — pré-existant, pas nouveau) |
| `test-inject-mcp-tools.sh` | 10 OK / 0 KO | 12 OK / 0 KO | 12 OK / 0 KO |

Les 7 cas nouveaux de `test-dev-orchestrator.sh` (T2g sous-cas A/B/C, T2h, T2i, T2j, T2k) et les 2
cas nouveaux de `test-inject-mcp-tools.sh` (T10, T11) sont tous verts sur les deux plateformes.
Aucun KO nouveau. T2c/T2e/T2f restent verts sans modification de leur code.

**Preuve Linux (commande exécutée) :**
```
docker run --rm -v "$(pwd)":/repo -w /repo ubuntu:24.04 bash -c '
  apt-get update -qq && apt-get install -y -qq python3 git >/dev/null 2>&1
  bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh
  bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
'
```
→ `rc1=0 rc2=0`, les deux bilans confirmés ci-dessus.

## Preuves structurelles (acceptance criteria du plan)

- `grep -v '^[[:space:]]*#' ensure-deps.sh | grep -c 'patch_gsd_executor_mcp'` → `2` (définition +
  unique appel de `main()`).
- `grep -c '@opengsd/gsd-core@\^1' ensure-deps.sh` → `2` (inchangé), et `git diff` ne montre
  **aucune** ligne modifiée contenant cette chaîne (vérifié `git diff ... | grep -E '^[+-]' | grep
  '@\^1'` → rien).
- `grep -v '^[[:space:]]*#' ensure-deps.sh | grep -c 'GSD_VERSION_FILE_NEW" \] || \[ -f
  "$GSD_VERSION_FILE_LEGACY'` → `0` (l'ancien test booléen a bien disparu).
- `grep -c 'command -v gsd' ensure-deps.sh` → `0` (piège n°1 non réintroduit).
- Corps de `log_legacy_cleanup_if_needed()` : `detect_gsd_legacy` n'y apparaît plus (vérifié par
  `awk` ciblé sur la fonction) — la fonction se déclenche uniquement sur l'état capturé.
- `grep -v '^[[:space:]]*#' ensure-deps.sh | grep -E 'npm uninstall|rm -rf|-empty -delete' | grep
  -vc '^[[:space:]]*log '` → `0` (aucune de ces commandes n'existe hors d'un argument de `log`).
- Dans le bloc python de `inject-mcp-tools.sh`, `os.replace` et l'ouverture en écriture
  (`open(tmp, "w", ...)`) n'apparaissent qu'aux lignes 297/299, dans la branche d'injection —
  aucune occurrence dans la branche `--verify` (qui `sys.exit()` avant de les atteindre).
- `bash "$SCRIPT" --argument-inconnu` → `rc=1` avec message d'erreur (non-régression du parsing).
- `grep -c 'verify' ensure-deps.sh` → `7` (≥ 1).
- `bash -n` → 0 sur les 4 fichiers modifiés.
- `git diff --name-only` (depuis avant ce plan) : exactement les 4 fichiers de `files_modified` du
  frontmatter, aucun autre.

## Decisions Made

- Capture de l'état legacy (nom, version) une seule fois en tête de `ensure_gsd()`, avant toute
  garde — nécessaire car l'installeur amont supprime lui-même le témoin `VERSION` legacy à
  l'install réussie (D-08.3), preuve directe apportée par T2k (stub `npx` qui supprime le fichier
  pendant son exécution, message quand même émis après coup).
- `npm_pkg_installed_globally()` est la seule fonction de ce chemin à réellement exécuter `npm`
  (requête `ls -g --depth=0`, lecture seule) — toutes les autres commandes potentiellement
  destructrices restent des arguments de `log` (ADR-031).
- Le mode `--verify` est implémenté comme une branche python entièrement séparée de l'injection
  (plutôt que de réutiliser le même code avec un flag conditionnel dispersé), pour garantir par
  construction qu'aucune instruction d'écriture n'y est atteignable — la preuve structurelle en
  découle directement (grep sur les lignes `os.replace`/`open(tmp, "w"`).
- Écart mineur assumé vis-à-vis du séquençage littéral suggéré par le plan (Task 1 puis Task 2
  puis Task 3) : les 3 tâches touchant `ensure-deps.sh` au même endroit (`ensure_gsd()`), le split
  en 3 commits atomiques a été reconstruit après implémentation complète plutôt que strictement
  task-par-task en un seul passage ; le contenu final est identique à ce qui aurait été produit en
  suivant l'ordre littéral (vérifié par diff contre la version testée en continu), seul l'ordre des
  micro-commits internes à `ensure_gsd()` diffère marginalement (commentaires "(Task 2)" retirés,
  T2i/T2j/T2k positionnés juste après T2d au lieu d'après T2h — sans effet fonctionnel, suites
  toujours vertes après reconstruction).

## Deviations from Plan

### Auto-fixed Issues

Aucune déviation au sens des règles 1-3 (aucun bug, aucune fonctionnalité critique manquante,
aucun blocage rencontré nécessitant un correctif hors périmètre). Le plan a été exécuté tel
qu'écrit, avec une seule adaptation d'ordre organisationnel documentée ci-dessus (reconstruction
du séquençage des commits, sans impact sur le contenu final ni sur les critères d'acceptation).

**Total deviations :** 0 auto-fixées. Impact sur le plan : aucun — tous les acceptance_criteria et
prohibitions (P-01 à P-07) du frontmatter sont satisfaits tels quels, aucun écart à faire remonter.

## Issues Encountered

Aucun. Le seul point d'attention pratique : simuler l'absence de `python3` pour tester le repli
`--verify` → exit 3 s'est révélé peu fiable sur macOS (`/usr/bin/python3` reste présent même avec
un `PATH` restreint à `/usr/bin:/bin`). Ce cas n'étant pas exigé par les `acceptance_criteria` de
Task 3 pour `test-inject-mcp-tools.sh` (T10/T11 ne le couvrent pas), le comportement a été vérifié
par lecture de code (le `if [ "$VERIFY" = "true" ]; then ... exit 3; fi` est sans ambiguïté) plutôt
que par un test automatisé fragile — noté ici pour transparence, pas un déficit fonctionnel.

## User Setup Required

None - aucune configuration de service externe requise.

## Known Stubs

Aucun.

## Threat Flags

Aucun — la surface de sécurité est celle déjà cadrée par le `<threat_model>` du plan (T-19-02-SC à
T-19-02-07), aucune surface nouvelle non couverte n'a été introduite.

## Self-Check: PASSED

- `plugin/dev-orchestrator/scripts/ensure-deps.sh` : FOUND (modifié, `bash -n` OK)
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` : FOUND (modifié, `bash -n` OK)
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` : FOUND (72 OK / 0 KO)
- `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` : FOUND (12 OK / 0 KO)
- Commit `70b5872` : FOUND (`git log --oneline --all | grep 70b5872`)
- Commit `15e42c7` : FOUND
- Commit `327e246` : FOUND
