---
phase: 30-portabilit-windows-ii
plan: 05
subsystem: infra
tags: [bash, windows-portability, python-resolution, hooks, install-engine, gitignore]

requires:
  - phase: 30-01
    provides: "merge-hooks.sh apprend args + --settings-local (forme exec, résolution bash absolue)"
provides:
  - "plugin/_internal/lib/vf-portable.sh — lib partagée d'engine, 5 symboles du contrat PR #29"
  - "copy_engine_lib() — pose la lib à l'install et à l'update, à plat, non exécutable"
  - "guard-file-size.sh, inject-mcp-tools.sh, test-dev-orchestrator.sh migrés sur la cascade partagée"
  - "somme de contrôle unique du bloc localisateur sur les 3 consommateurs"
  - "routage --settings-local côté vibeflow-update.sh (merge + remove) + .gitignore local étendu"
affects: [30-06, 30-07, 30-08, willy-gouvernance-pr29]

actuals:
  tokens: 10193
  tasks: 4
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Bloc localisateur à remontée bornée (<=4 niveaux) plutôt qu'à profondeur fixe — résout le
       cas d'un consommateur niché plus profond (scripts/tests/) sans dupliquer le bloc"
    - "Fonction bash (pas variable) pour porter un lanceur à argument (py -3)"
    - "Contrat de marqueur en 3 actions groupées (écriture atomique + stderr + code de sortie rendu)"

key-files:
  created:
    - plugin/_internal/lib/vf-portable.sh
    - plugin/_internal/tests/test-vf-portable.sh
    - .planning/phases/VFDO-30-portabilit-windows-ii/30-RELIQUATS.md
  modified:
    - plugin/_internal/vibeflow-update.sh
    - plugin/_internal/tests/test-vibeflow-update.sh
    - plugin/software-architecture/scripts/guard-file-size.sh
    - plugin/dev-orchestrator/scripts/inject-mcp-tools.sh
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh

key-decisions:
  - "D-05 appliquée : hook doctor de conductor DIFFÉRÉ avec reliquat écrit (30-RELIQUATS.md), pas de version minimale — le report est sans danger car vf_guard_unavailable imprime déjà le motif sur stderr à chaque occurrence"
  - "Bloc localisateur : candidat 3 remplacé par une remontée BORNÉE (<=4 niveaux, jamais liée au CWD) au lieu d'un chemin relatif fixe, pour que le MÊME bloc résolve correctement depuis scripts/ (2 niveaux) ET scripts/tests/ (3 niveaux) sans dupliquer le bloc entre consommateurs"
  - "Code de vf_guard_unavailable fixé à 17 — non nul, différent de 2 (D-02), valeur arbitraire mais stable et documentée"
  - "test-dev-orchestrator.sh migré bien que non nommé au contrat §7 — reliquat 2 tracé, raison et destinataire écrits"

patterns-established:
  - "Bloc localisateur canonique entre marqueurs # >>> / # <<< vf-portable:locator, prouvé identique par somme de contrôle sur test-vf-portable.sh (anticipe le gate amont non encore livré)"

requirements-completed: [PORT-01]

coverage:
  - id: D1
    description: "Lib vf-portable.sh — 5 symboles du contrat (vf_resolve_python, vf_python fonction, vf_py_probe deux profils, jqx, vf_guard_unavailable), IS_WINDOWS portée par la lib, écriture atomique du marqueur"
    requirement: "PORT-01"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vf-portable.sh (T1-T8)"
        status: pass
    human_judgment: false
  - id: D2
    description: "copy_engine_lib() pose la lib à l'install ET à l'update (resync version inchangée), à plat, non exécutable, échec de pose = échec d'install (VG-3)"
    requirement: "PORT-01"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vf-portable.sh (T9-T11)"
        status: pass
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh (suite complète, 13 cas)"
        status: pass
    human_judgment: false
  - id: D3
    description: "3 consommateurs PYBIN migrés (guard-file-size.sh profil rapide + renversement du silence, inject-mcp-tools.sh profil complet + contrat --verify intact, test-dev-orchestrator.sh 3 gardes de saut) ; identité du bloc localisateur prouvée par somme de contrôle unique"
    requirement: "PORT-01"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vf-portable.sh (T12-T13)"
        status: pass
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh (184 cas)"
        status: pass
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh (26 cas)"
        status: pass
      - kind: unit
        ref: "plugin/software-architecture/scripts/tests/test-guard-file-size.sh (15 cas)"
        status: pass
      - kind: unit
        ref: "plugin/consolidator/scripts/tests/test-windows-guards.sh (9 cas)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Routage --settings-local côté vibeflow-update.sh (merge + remove, project/local seulement) + .gitignore local étend à .claude/settings.json (data-driven, module à hooks) et .claude/scripts/vf-portable.sh"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh (T3c + négatif)"
        status: pass
      - kind: unit
        ref: "plugin/_internal/tests/test-merge-hooks.sh (23 cas, T15-T18 déjà existants restent verts)"
        status: pass
    human_judgment: false

duration: 22min
completed: 2026-08-15
status: complete
---

# Phase 30 Plan 05: Lot PYBIN — lib partagée vf-portable.sh Summary

**La lib de résolution Python centralisée écrite from scratch en conformité au contrat PR #29
(non mergé), posée par l'engine à l'install/update, et les 3 consommateurs du périmètre dev migrés
avec identité du bloc localisateur prouvée par somme de contrôle machine.**

## Performance

- **Duration:** ~22 min (entre le commit de la tâche 1 et celui de la tâche 4 ; lecture du contrat
  + du code source en amont non comptée)
- **Started:** 2026-08-15T21:23:45Z (commit tâche 1)
- **Completed:** 2026-08-15T21:45:21Z (commit tâche 4)
- **Tasks:** 4/4
- **Files modified:** 8 (3 créés, 5 modifiés)

## Accomplishments

- `plugin/_internal/lib/vf-portable.sh` écrite de zéro : les 5 symboles exacts du contrat PR #29,
  deux profils de sonde (complet / rapide zéro-spawn), contrat de marqueur en 3 actions groupées.
- `copy_engine_lib()` pose la lib à l'install ET au resync gouvernance (version inchangée) — un lab
  qui n'a jamais fait d'update après cette phase reçoit quand même la lib au premier appel.
- Les 3 fichiers du lot PYBIN dev (`guard-file-size.sh`, `inject-mcp-tools.sh`,
  `test-dev-orchestrator.sh`) ne portent plus aucune résolution Python locale — vérifié par grep,
  pas par lecture. Identité de leur bloc localisateur prouvée par une somme de contrôle unique.
- `guard-file-size.sh` : le silence est renversé — une garde qui ne peut pas tourner écrit un
  marqueur, imprime le motif sur stderr, et sort avec un code non nul différent de 2 (D-02), au
  lieu du `exit 0` muet d'avant.
- Routage `--settings-local` câblé côté `vibeflow-update.sh` (merge ET remove), et `.gitignore`
  local étendu pour couvrir `.claude/settings.json` (module à hooks) et
  `.claude/scripts/vf-portable.sh` (gap constaté et corrigé pendant l'exécution).

## Task Commits

Each task was committed atomically:

1. **Tâche 1 : lib `vf-portable.sh` et sa suite** - `ef666cf` (feat)
2. **Tâche 2 : `copy_engine_lib()`** - `e79dc1c` (feat)
3. **Tâche 3 : migrer les 3 consommateurs + identité du bloc** - `9da6c4a` (feat)
4. **Tâche 4 (amendement) : routage `--settings-local` + `.gitignore` local** - `b4406d1` (feat)

_Note : aucune tâche n'était `tdd="true"` — pas de commits test/feat/refactor séparés._

## Files Created/Modified

- `plugin/_internal/lib/vf-portable.sh` (créé) - lib partagée, 5 symboles du contrat, IS_WINDOWS
- `plugin/_internal/tests/test-vf-portable.sh` (créé) - 13 cas (T1-T13), 3 mutations rejouées
- `plugin/_internal/vibeflow-update.sh` (modifié) - `copy_engine_lib()`, routage
  `--settings-local`, `.gitignore` étendu (settings.json + vf-portable.sh)
- `plugin/_internal/tests/test-vibeflow-update.sh` (modifié) - T3c + cas négatif (2 nouveaux cas)
- `plugin/software-architecture/scripts/guard-file-size.sh` (modifié) - bloc localisateur, profil
  rapide, renversement du silence
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (modifié) - bloc localisateur, profil
  complet, contrat --verify intact
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (modifié) - bloc localisateur,
  3 gardes de saut migrées, fixture T2n corrigée (lib copiée à plat à côté de l'injecteur isolé)
- `.planning/phases/VFDO-30-portabilit-windows-ii/30-RELIQUATS.md` (créé) - 2 reliquats tracés

## Décisions et conformité au contrat

### D-05 — hook doctor `conductor` : DIFFÉRÉ

Tranché sur pièces (CONTEXT.md laissait le choix au planner) : **différé, avec reliquat écrit**,
pas de version minimale. Raison : le hook appartient à la polarité gouvernance et son ajout aurait
exigé de toucher un fragment `hooks/hooks.json` hors du périmètre strict de ce plan. **Pourquoi le
report est sans danger** : `vf_guard_unavailable` imprime déjà le motif sur stderr **immédiatement**
à chaque occurrence (l'utilisateur voit le problème avant même qu'un agrégateur existe), et
l'écriture du marqueur est atomique + fail-safe — les marqueurs s'accumulent sans jamais casser
l'appelant. Détail complet, raison et destinataire : `30-RELIQUATS.md` reliquat 1.

### Conformité point par point au contrat PR #29 (§2/§3/§4)

| Exigence du contrat | Statut | Preuve |
|---|---|---|
| 5 symboles exacts (`vf_resolve_python`, `vf_python` fonction, `vf_py_probe`, `jqx`, `vf_guard_unavailable`) | ✅ | `test-vf-portable.sh` T2 (`type` rend 5 fonctions) |
| `vf_python` est une FONCTION, pas une variable `PYBIN=` | ✅ | `grep -cE '^[[:space:]]*(PYBIN|VF_PYTHON)=' vf-portable.sh` == 0 |
| `IS_WINDOWS` portée par la lib, inconditionnelle au chargement | ✅ | Calculée hors de toute fonction, à la simple source du fichier |
| Cascade `python3 → python → py -3` | ✅ | `vf_resolve_python` itère exactement ces 3 candidats dans cet ordre |
| `vf_py_probe` rejette le stub `*WindowsApps*` par CHEMIN | ✅ | T4 (stub qui délègue au vrai python3 — seul le rejet par chemin l'exclut, mutation m1 le prouve) |
| Deux profils de sonde (complet avec `timeout`, rapide zéro-spawn) | ✅ | T5 (compteur de shim, 0 process en `--fast`) + mutation m3 |
| `vf_guard_unavailable` : marqueur + stderr + code rendu, jamais un `exit` interne | ✅ | T6/T7 + mutation m2 ; la fonction fait `return`, jamais `exit` |
| Code de `vf_guard_unavailable` non nul et **différent de 2** (D-02) | ✅ | `VF_GUARD_UNAVAILABLE_EXIT_CODE=17` |
| Bloc localisateur à 4 candidats, marqueurs `# >>> / # <<< vf-portable:locator` | ✅ | Présent dans les 3 consommateurs, une paire chacun |
| Bloc IDENTIQUE entre consommateurs, seul le préfixe de message varie | ✅ | T12 — une seule somme de contrôle après normalisation du jeton `[préfixe]` |
| Aucun candidat trouvé ⇒ message préfixé stderr + sortie non nulle, jamais un `source` muet | ✅ | Testé sur fixtures T13 + comportement réel des 3 consommateurs |
| `copy_engine_lib()` pose à plat, non exécutable, écriture atomique | ✅ | T9 (`test ! -x`, `cmp` identique) ; tmp+rename dans le même répertoire |
| Échec de pose = échec d'install, jamais un succès silencieux (VG-3) | ✅ | T11 + mutation (retour neutre) — T11 rougit sur ses deux assertions |

**Écart assumé vis-à-vis du bloc localisateur ILLUSTRATIF du contrat** : le contrat montre un
candidat 3 à profondeur FIXE (`$(dirname "$0")/../../_internal/lib/vf-portable.sh`, 2 niveaux).
Ce chemin fixe ne résout PAS pour `test-dev-orchestrator.sh`, niché un niveau plus profond
(`scripts/tests/`, 3 niveaux). Le candidat 3 réel de ce plan est donc une **remontée bornée
(≤4 niveaux)** depuis `$(dirname "$0")` — même mécanisme, jamais lié au CWD (pas de régression sur
le motif de confinement de chemin fermé en Phase 27, ADR-070), qui résout correctement pour les 3
profondeurs réelles du dépôt (2 niveaux pour les 2 fichiers de production, 3 niveaux pour la suite
de test) avec un **bloc parfaitement identique** entre les 3 consommateurs. Documenté dans le
commentaire du bloc lui-même et repris ici pour traçabilité.

### Sémantique `vf_py_probe` — les deux profils employés où prévu

- `guard-file-size.sh` (PreToolUse, tourne à CHAQUE Edit/Write) → **profil rapide** (`--fast`,
  détection par chemin seule, zéro spawn ajouté — amendement ADR-054 point 3).
- `inject-mcp-tools.sh` (script d'install, pas de contrainte de latence) → **profil complet**
  (sonde d'exécution réelle, gardée par `timeout`).
- `test-dev-orchestrator.sh` (gardes de saut, pas de contrainte de latence) → **profil complet**
  (`vf_resolve_python` sans `--fast`).

## Preuves par mutation (citées, traces réelles)

### Tâche 1 — `test-vf-portable.sh`

**m1 — retirer l'exclusion du stub `*WindowsApps*`** (`vf_py_probe`) :
```
✗ T4 candidat stub *WindowsApps* accepté à tort (rc=0)
== 7 ok · 1 ko · 0 skip ==
```
Revert → `8 ok · 0 ko`.

**m2 — `vf_guard_unavailable` rend `0` au lieu du code non nul** :
```
✗ T6 code rendu = 0 (attendu non nul)
✗ T7 code rendu = 0 malgré répertoire non créable
== 6 ok · 2 ko · 0 skip ==
```
Revert → `8 ok · 0 ko`.

**m3 — le profil rapide lance quand même un processus** (early-return `--fast` retiré) :
```
✗ T5 profil rapide (--fast) : 1 processus python3 lancé(s) — régression de latence
== 7 ok · 1 ko · 0 skip ==
```
Revert → `8 ok · 0 ko`.

### Tâche 2 — propagation d'échec `copy_engine_lib()` (retour neutre au lieu de VG-3)

Mutation : `return 1` → `return 0` sur le chemin « lib source introuvable » :
```
✗ T11 install exit 0 malgré la lib source absente
✗ T11 module marqué installé alors que la lib de portabilité n'a pas pu être posée
== 10 ok · 2 ko · 0 skip ==
```
Revert → `11 ok · 0 ko`.

### Tâche 3 — identité du bloc localisateur (une ligne modifiée dans UN SEUL consommateur)

Mutation sur `inject-mcp-tools.sh` seul (candidat 4 renommé `vf-portable-MUTATED.sh`) :
```
guard-file-size.sh=fe93197b54bdf4c32465d9dc03b3aff65d7c524f3bb9be98298cc1555838d520
inject-mcp-tools.sh=5c756a7ed00576f4ac97ba11c3e272e6945ef23946dd3105cab53fc79a39885d
test-dev-orchestrator.sh=fe93197b54bdf4c32465d9dc03b3aff65d7c524f3bb9be98298cc1555838d520
✗ T12 identité du bloc : sommes DIVERGENTES
== 12 ok · 1 ko · 0 skip ==
```
Le fichier divergent est nommé sans ambiguïté (2 sommes identiques, 1 différente, portée par le
fichier muté). Revert → `13 ok · 0 ko`.

### Tâche 4 — `.claude/settings.json` non gitignoré (ligne commentée dans `gitignore_add_paths()`)

```
✗ T3c local : .claude/settings.json apparaît 0 fois dans .gitignore (attendu 1)
== résultat : 12 OK / 1 KO / 0 SKIP ==
```
Revert → `13 OK / 0 KO / 0 SKIP`.

## Preuves par exécution (acceptance criteria tâche 3)

**Renversement du silence** (PATH sans aucun interpréteur Python → `guard-file-size.sh`) :
```
[guard-file-size.sh] aucun interprète Python utilisable (profil rapide, PreToolUse)
rc=17 (non nul, != 2)
marqueur : 2026-08-15T21:38:03Z	guard-file-size.sh	aucun interprète Python utilisable (profil rapide, PreToolUse)
```

**Profil zéro-spawn** — compteur de shim sur cas nominal (petit `Write`, Python fonctionnel) :
`spawns=1` après migration. Avant migration, le bloc PYBIN historique ne spawnait pas non plus à
la RÉSOLUTION (`command -v` seul), et le SEUL spawn était l'invocation finale `"$PYBIN" -c '...'`
— donc **1 avant, 1 après migration**, identique (le profil rapide n'ajoute aucun spawn de sonde).

**Contrat `inject-mcp-tools.sh --verify` intact sans Python** :
```
[inject-mcp-tools] ERROR: python3 requis pour --verify — verdict INDÉTERMINÉ (jamais un faux vert).
rc=3
```
Code et message identiques à avant la migration (seule la résolution de l'interpréteur a changé,
pas le comportement observable).

## Écart de comptage — tâche 4 (mandat ~12 vs réel)

Le mandat amont évoquait « ~12 occurrences » de `settings.json` justifiant potentiellement une
correction du garde-fou anti-pollution `snapshot_home_claude()` de `test-vibeflow-update.sh`.
Lecture réelle du fichier : **2 occurrences** de la chaîne `settings.json` dans ce fichier
(lignes 46 et 51, toutes deux dans `snapshot_home_claude()`, qui balaie `$HOME/.claude/settings.json`).
`snapshot_home_claude()` reste correcte telle quelle : elle ne couvre que le **scope user**, et
`settings.local.json` n'est **jamais** produit en scope user (D-01 : no-op assumé pour ce scope,
`$HOME/.claude` est déjà par-machine). Aucune correction n'était due sur ce fichier — le geste
réellement demandé par la mission (routage + gitignore) est celui livré ci-dessus (T3c). Consigné
ici plutôt qu'inventé sans cible réelle.

## Decisions Made

- Voir « Décisions et conformité au contrat » ci-dessus pour D-05 et l'écart de bloc localisateur.
- Code `VF_GUARD_UNAVAILABLE_EXIT_CODE=17` — non nul, différent de 2, valeur arbitraire mais stable
  et documentée dans `vf-portable.sh`.
- `copy_engine_lib()` appelée depuis `install_module()` ET `sync_module_governance()`, gardée
  idempotente intra-processus (`VF_ENGINE_LIB_COPIED`) plutôt qu'appelée une seule fois au niveau
  du dispatch — plus simple à garantir correcte sur les DEUX chemins requis sans dupliquer la
  logique de dispatch (`install --all`, `install --with-deps`, `update --all`, appels directs).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixture T2n de `test-dev-orchestrator.sh` cassée par la migration d'`inject-mcp-tools.sh`**
- **Found during:** Tâche 3 (migration des 3 consommateurs)
- **Issue:** T2n copie `inject-mcp-tools.sh` SEUL dans un répertoire temporaire isolé (sans la lib
  à côté) pour tester le chaînage réel `ensure-deps.sh` → injecteur. Après migration, l'injecteur
  source `vf-portable.sh` via le bloc localisateur — introuvable dans ce répertoire isolé, la
  garde de saut `command -v python3` avait été remplacée mais le vrai défaut était la lib absente.
- **Fix:** Copie de `plugin/_internal/lib/vf-portable.sh` à plat dans le même répertoire temporaire
  que l'injecteur — reproduit EXACTEMENT le geste réel de `copy_engine_lib()` à l'install (même
  répertoire de scripts).
- **Files modified:** `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`
- **Verification:** `184 OK / 0 KO / 0 SKIP` (contre 183 OK / 1 KO avant le fix)
- **Committed in:** `9da6c4a` (tâche 3)

**2. [Rule 1/2 - Bug de conception] Bloc localisateur à profondeur fixe ne résolvait pas pour un
consommateur niché plus profond**
- **Found during:** Tâche 3 (conception du bloc avant migration de `test-dev-orchestrator.sh`)
- **Issue:** Le candidat 3 illustratif du contrat (`../../_internal/lib/vf-portable.sh`, 2 niveaux
  fixes) ne résout que pour des scripts vivant à `plugin/<module>/scripts/*.sh`. `test-dev-orchestrator.sh`
  vit à `plugin/<module>/scripts/tests/*.sh` (3 niveaux) — aucun des 4 candidats fixes ne l'aurait
  atteint, cassant soit l'identité du bloc (candidat propre à ce fichier) soit sa résolution.
- **Fix:** Candidat 3 remplacé par une remontée BORNÉE (boucle 1..4 niveaux) depuis
  `$(dirname "$0")`, jamais liée au CWD — un seul bloc, identique, résout correctement aux deux
  profondeurs réelles du dépôt.
- **Files modified:** les 3 consommateurs (bloc identique)
- **Verification:** T12 rend une somme de contrôle unique pour les 3 fichiers
- **Committed in:** `9da6c4a` (tâche 3)

**3. [Rule 2 - Missing Critical] `.claude/scripts/vf-portable.sh` non gitignoré en scope local**
- **Found during:** Tâche 4 (vérification manuelle du routage `--settings-local`)
- **Issue:** `copy_engine_lib()` (tâche 2, ce même plan) pose `vf-portable.sh` à plat dans
  `$TARGET_ROOT/scripts/` à CHAQUE exécution de l'engine — y compris en scope local, où la promesse
  SCOPE-04 est « rien ne sera committé ». Aucune ligne de `gitignore_add_paths()` ne couvrait ce
  fichier (il vient du cache `_internal`, jamais de `$module_dir/scripts`, donc invisible à la
  boucle existante).
- **Fix:** Ligne inconditionnelle `gitignore_add_one ".claude/scripts/vf-portable.sh"` ajoutée en
  fin de `gitignore_add_paths()` (idempotente par construction).
- **Files modified:** `plugin/_internal/vibeflow-update.sh`
- **Verification:** vérifié manuellement (install en scope local, `.gitignore` contient la ligne) ;
  aucun test dédié écrit (hors du périmètre explicite de la tâche 4, geste minimal et sans risque)
- **Committed in:** `b4406d1` (tâche 4)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 - bugs révélés par la migration, 1 Rule 2 - gap de
gitignore introduit par la tâche 2 de ce même plan)
**Impact on plan:** Les trois corrections étaient nécessaires pour que le plan livre ce qu'il
promet (suite verte à 184/184, bloc identique aux 3 profondeurs réelles, promesse SCOPE-04 tenue
pour un fichier que ce plan lui-même introduit). Aucun élargissement de périmètre au-delà des 8
fichiers autorisés.

## Issues Encountered

- Le sweep complet de toutes les suites du dépôt (`find plugin scripts -type f -path '*/tests/test-*.sh'`)
  révèle 2 échecs préexistants dans des fichiers **explicitement prohibés** pour ce plan
  (`plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh` et
  `test-discover-unintegrated-docs.sh`), tous deux liés à la normalisation des codes de sortie
  `--hook` (travail du plan 30-04, concurrent, commité juste avant ce plan sur la même branche).
  Aucun rapport avec la résolution Python/PYBIN de ce plan (vérifié : les échecs portent sur
  `exit 3` vs `exit 0` en mode `--hook`, pas sur une invocation Python). Non touché, non corrigé —
  hors du périmètre autorisé de ce plan, signalé ici pour traçabilité seulement.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Le lot PYBIN dev est clos : les 3 fichiers passent par la cascade partagée, l'identité de leur
  bloc est prouvée à la machine, la garde ne ment plus quand elle ne peut pas tourner.
- `copy_engine_lib()` est disponible et appelée sur les deux chemins qui posent des fichiers —
  tout plan/phase suivant qui migre d'autres consommateurs PYBIN (polarité gouvernance, Willy)
  peut réutiliser le même bloc localisateur et le même mécanisme de somme de contrôle sans
  réinventer ni la lib ni la pose.
- Reliquat 1 (hook doctor `conductor`) reste ouvert, sans urgence (report sans danger documenté).
- Reliquat 2 (`test-dev-orchestrator.sh` hors contrat §7) à signaler à Willy quand le gate amont
  `check-portable-resolution.sh` sera écrit, pour qu'il tranche s'il inclut les suites de test.
- Aucun blocage pour les plans 30-06/30-07/30-08 (hooks.json forme exec, codes de sortie du reste
  du parc) — ce plan ne touche à aucun `hooks/hooks.json`.

---
*Phase: 30-portabilit-windows-ii*
*Completed: 2026-08-15*

## Self-Check: PASSED

- FOUND: plugin/_internal/lib/vf-portable.sh
- FOUND: plugin/_internal/tests/test-vf-portable.sh
- FOUND: .planning/phases/VFDO-30-portabilit-windows-ii/30-RELIQUATS.md
- FOUND: .planning/phases/VFDO-30-portabilit-windows-ii/30-05-SUMMARY.md
- FOUND: plugin/_internal/vibeflow-update.sh
- FOUND: plugin/_internal/tests/test-vibeflow-update.sh
- FOUND: plugin/software-architecture/scripts/guard-file-size.sh
- FOUND: plugin/dev-orchestrator/scripts/inject-mcp-tools.sh
- FOUND: plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
- Commits FOUND in git log: ef666cf, e79dc1c, 9da6c4a, b4406d1
