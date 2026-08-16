---
phase: VFDO-30-portabilit-windows-ii
plan: 09

subsystem: infra
tags: [bash, hooks, claude-code, windows-portability, dev-orchestrator, adr-071, sessionstart]

requires:
  - phase: VFDO-30-06
    provides: hook_exit() posé dans les 4 scripts dev-orchestrator, contrat de sortie durable
  - phase: VFDO-30-07
    provides: les 4 entrées SessionStart de dev-orchestrator en forme exec (command={{VF_BASH}} résolu, args)
provides:
  - Filet SessionStart advisory (check-hook-paths.sh) qui constate la péremption d'un chemin d'interpréteur figé à l'install au lieu de laisser le hook mourir en silence
  - Entrée de hook n°26 (dev-orchestrator/hooks/hooks.json) — seule entrée du parc à `command` nom nu littéral, dérogation nommée à ADR-071 §Décision 2
  - Suite de discrimination test-check-hook-paths.sh (61e suite du dépôt), 12 cas + 4 mutations tracées
  - Inventaire durable (docs/HOOKS-CONTRAT-SORTIE.md) porté à 26 entrées, prouvé par recompte machine
  - dev-orchestrator v2.17.0
affects: [30-08]

actuals:
  tokens: 14804
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Filet SessionStart auto-diagnostique invoqué par nom nu (paradoxe d'amorçage) plutôt que par le chemin qu'il surveille"
    - "Trois issues (silence/constat/verdict-non-rendu) + mutation rouge tracée pour tout gate de hook (QUAL-01)"

key-files:
  created:
    - plugin/dev-orchestrator/scripts/check-hook-paths.sh
    - plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh
  modified:
    - plugin/dev-orchestrator/hooks/hooks.json
    - docs/HOOKS-CONTRAT-SORTIE.md
    - plugin/dev-orchestrator/VERSION
    - plugin/dev-orchestrator/module.json
    - plugin/dev-orchestrator/CHANGELOG.md
    - plugin/dev-orchestrator/README.md

key-decisions:
  - "L'entrée de hook n°26 porte un command littéral `bash`, jamais le jeton {{VF_BASH}} — dérogation à ADR-071 §Décision 2, autorisée par l'approbation humaine de l'addendum du 2026-08-15, jamais par l'ADR elle-même (qui ne documente pas encore ce cas)."
  - "T11 de la suite de tests utilise un fragment synthétique autoportant plutôt que le hooks.json vivant, pour rester découplé de la mutation m3 (qui ne doit rougir que T9) — corrigé après une première trace qui violait « attendu rouge T9 seul »."
  - "T12 tolère explicitement l'écart transitoire doc/parc (25 déclaré vs 26 réel) entre la tâche 1 (pose l'entrée) et la tâche 3 (met à jour l'inventaire) de ce même plan — SKIP bruyant borné à cette signature exacte, KO sur tout autre écart."

patterns-established:
  - "Un filet qui diagnostique la péremption d'une résolution figée à l'install ne doit jamais dépendre de cette même résolution pour s'exécuter lui-même."

requirements-completed: [PORT-03, PORT-04, QUAL-01]

coverage:
  - id: D1
    description: "check-hook-paths.sh détecte un chemin de hook absolu introuvable (command ou args) et reste strictement silencieux (0 octet stdout) sur le chemin nominal"
    requirement: "QUAL-01"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh#T1,T2,T2b"
        status: pass
    human_judgment: false
  - id: D2
    description: "Réglages illisibles/JSON invalide → stderr bruyant nommant le fichier, stdout vide, rc 1 jamais 2, inchangé sous --hook"
    requirement: "QUAL-01"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh#T4"
        status: pass
    human_judgment: false
  - id: D3
    description: "L'entrée de hook n°26 porte un command littéral bash, jamais le jeton d'interpréteur — dérogation ADR-071 gardée à la machine"
    requirement: "PORT-04"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh#T9"
        status: pass
    human_judgment: false
  - id: D4
    description: "Inventaire durable (docs/HOOKS-CONTRAT-SORTIE.md) porté à 26 entrées, recompte machine vert"
    requirement: "PORT-03"
    verification:
      - kind: other
        ref: "python3 -c \"...assert n==26, n\" (docs/HOOKS-CONTRAT-SORTIE.md §4)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Discriminance du filet prouvée par 4 mutations (m1-m4), chacune reddening exactement le sous-ensemble de cas attendu"
    requirement: "QUAL-01"
    verification:
      - kind: other
        ref: "traces de mutation manuelles, consignées en en-tête de test-check-hook-paths.sh et ci-dessous"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-08-15
status: complete
---

# Phase 30 Plan 09: Le filet de péremption des chemins de hook (addendum) Summary

**check-hook-paths.sh — 5e signal SessionStart advisory qui constate un chemin d'interpréteur figé à l'install devenu périmé, invoqué par nom nu (dérogation nommée à ADR-071 §Décision 2, autorisée par l'approbation humaine de l'addendum du 2026-08-15) et gardé à la machine par mutation.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-08-15T22:52:00Z
- **Completed:** 2026-08-15T23:47:02Z
- **Tasks:** 3/3
- **Files modified:** 8 (2 créés, 6 modifiés)

## Accomplishments

- `check-hook-paths.sh` créé : relit `.claude/settings.json` + `.claude/settings.local.json` (scope
  projet, obligatoires) et le scope utilisateur (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}`, écarté par
  comparaison de chaînes s'il désigne le même chemin), vérifie chaque chemin absolu d'une entrée en
  forme exec, et rend un signal borné à 7 lignes sur constat — zéro octet sur le chemin nominal.
- Entrée n°26 câblée dans `plugin/dev-orchestrator/hooks/hooks.json` : `command` littéral `bash`
  (seule entrée du parc dans ce cas), `args` = script + `--hook`. `description` du fragment mise à
  jour pour citer le 5e signal et sa raison.
- Suite `test-check-hook-paths.sh` (61e suite du dépôt) : 12 cas (T1, T2, T2b, T3, T4, T5×2, T6, T7,
  T8, T9, T10, T11×3, T12), 4 mutations rejouées manuellement avec traces consignées en en-tête.
- Inventaire durable `docs/HOOKS-CONTRAT-SORTIE.md` porté à 26 (six emplacements de décompte mis à
  jour ensemble), paragraphe de dérogation ajouté.
- `dev-orchestrator` v2.16.0 → v2.17.0 (VERSION, `module.json`, en-tête README, CHANGELOG).

## Task Commits

1. **Tâche 1 (tracer) : le filet de bout en bout** — `dae62ec` (feat)
2. **Tâche 2 (auto, tdd) : la suite de discrimination** — `dc37e07` (test)
3. **Tâche 3 (auto) : inventaire + bump module** — `2c638f2` (docs, inventaire) + `e1c88bb` (chore, bump)

_Note : la tâche 3 produit deux commits atomiques distincts, comme prescrit par le plan._

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/check-hook-paths.sh` — le filet lui-même (368 lignes)
- `plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` — sa suite de discrimination (407 lignes)
- `plugin/dev-orchestrator/hooks/hooks.json` — 5e entrée SessionStart
- `docs/HOOKS-CONTRAT-SORTIE.md` — inventaire 25 → 26
- `plugin/dev-orchestrator/VERSION`, `module.json`, `README.md`, `CHANGELOG.md` — bump v2.17.0

## Décisions prises

- **Découplage de T11 du hooks.json vivant** (Rule 1 — bug découvert pendant la vérification par
  mutation) : la première version de T11 lisait directement `plugin/dev-orchestrator/hooks/hooks.json`
  pour exercer `merge-hooks.sh`. Sous la mutation m3 (command littéral → jeton), `is_local_entry()`
  du moteur de fusion route alors l'entrée vers le fichier LOCAL — un comportement réel et correct
  du moteur, mais qui faisait rougir T11a EN PLUS de T9, violant l'exigence du plan « m3 : attendu
  rouge T9 seul ». Fix : T11 construit désormais un fragment JSON synthétique autoportant, de même
  forme que l'entrée réelle, jamais lu depuis le hooks.json vivant — le mécanisme du moteur de
  fusion reste prouvé, sans coupler T11 à la garde spécifique de T9. Reproduit et vérifié après
  correction (trace ci-dessous).
- **T12 tolère un écart transitoire nommé** plutôt que d'échouer aveuglément : ce plan pose la 26e
  entrée à la tâche 1 mais ne met à jour l'inventaire durable qu'à la tâche 3 — entre les deux, le
  recompte réel (26) diverge nécessairement du nombre déclaré par le document (25). T12 distingue
  cet écart EXACT (+1, la signature de « tâche 3 pas encore jouée ») par un SKIP bruyant et nommé,
  de tout autre écart (KO). Après la tâche 3, docs et parc convergent et T12 devient OK — revérifié
  ci-dessous.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] T11 couplé par erreur à la mutation m3 (via lecture directe du hooks.json vivant)**
- **Found during:** Tâche 2, pendant l'exécution manuelle de la mutation m3 pour tracer sa preuve
- **Issue:** T11 lisait `$HOOKS_JSON` (le fichier réel) pour exercer `merge-hooks.sh`. La mutation
  m3 (command littéral → `{{VF_BASH}}`) fait légitimement router l'entrée vers le fichier local
  (`is_local_entry()`), donc T11a rougissait aussi — en violation de « m3 : attendu rouge T9 seul »
  du plan.
- **Fix:** T11 construit un fragment JSON synthétique (`$FRAG_T11`), de même forme que l'entrée
  réelle, jamais lu depuis le hooks.json vivant — mécanisme du moteur de fusion prouvé
  indépendamment de l'état de hooks.json.
- **Files modified:** `plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh`
- **Verification:** Suite rejouée sous m3 après correction : seul T9 rouge, T11a/b/c restés verts.
- **Committed in:** `dc37e07` (part of task 2 commit — corrigé avant le commit, pas de commit
  séparé)

---

**Total deviations:** 1 auto-fixed (1 bug, Rule 1)
**Impact on plan:** Correction interne à la tâche 2, avant tout commit — n'affecte ni le périmètre
ni les fichiers listés par le plan. Aucun scope creep.

## Traces de mutation (QUAL-01 — discriminance prouvée, pas affirmée)

Les 4 mutations ont été rejouées manuellement contre le script/hooks.json livrés (copie de travail
restaurée après coup, byte-identique vérifiée par `diff`, suite revérifiée verte après chaque
restauration). Traces complètes également consignées en en-tête de
`plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh`.

- **m1 — neutraliser le contrôle d'existence du chemin** (`os.path.isfile`/`os.access` toujours
  vrais dans le bloc Python embarqué). Attendu rouge : T2, T2b, T5 (deux sous-cas). Attendu vert :
  T1, T4, T6, T7.
  **Obtenu :** exactement T2/T2b/T5a/T5b rouges (`rc=3, stdout vide` au lieu du signal attendu) ;
  T1/T4/T6/T7 (et T3/T8/T9/T10/T11) restés verts. Résultat : **11 OK, 4 KO** sous mutation.
- **m2 — avaler l'erreur d'analyse** (JSON invalide traité comme fichier absent, silencieux, au
  lieu d'émettre `PARSE_ERROR`). Attendu rouge : T4 seul.
  **Obtenu :** T4 rouge exactement (attendu "stderr nommant le fichier fautif, rc 1", obtenu
  "stderr générique '0 entrée(s) examinée(s)... rien à signaler', rc 3 sans --hook / rc 0 sous
  --hook" — le faux PASS silencieux que QUAL-01 interdit). Tous les autres cas verts. Résultat :
  **14 OK, 1 KO** sous mutation.
- **m3 — remplacer, dans une copie de hooks.json, le command littéral `bash` par le jeton
  `{{VF_BASH}}`**. Attendu rouge : T9 seul.
  **Obtenu (après correction du couplage T11, voir Décisions ci-dessus) :** T9 rouge exactement
  (attendu "command == 'bash' littéral", obtenu "command == '{{VF_BASH}}'"). T11 (fragment
  synthétique) resté vert. Résultat : **14 OK, 1 KO** sous mutation.
- **m4 — retirer `.claude/settings.local.json` de la liste des candidats**. Attendu rouge : le
  second sous-cas de T5 seul.
  **Obtenu :** T5 sous-cas b rouge exactement (attendu "signal émis", obtenu "stdout vide, rc 3" —
  le fichier local n'est simplement plus lu). T5 sous-cas a et tout le reste restés verts. Résultat :
  **14 OK, 1 KO** sous mutation.

Chaque mutation restaurée byte-identique (`diff` vide), suite revérifiée verte (**15 OK, 0 KO, 1
SKIP**) après chaque restauration.

## Non-régression sur le parc entier (tâche 3)

- **Découverte** (`find plugin scripts -type f -path '*/tests/test-*.sh'`) : **61 suites** (60
  avant ce plan + 1, `test-check-hook-paths.sh`).
- **Exécution** : les **61 suites** exécutées, **0 échec**.
- `bash scripts/check-machine-paths.sh` → `0` (1011 fichiers suivis balayés, aucun chemin de
  machine versionné).
- `bash plugin/conductor/scripts/check-state-integrity.sh` → `0` (STATE.md conforme).
- `bash scripts/check-version-sync.sh` → verdict ligne à ligne :
  - ✓ `plugin.json` 2.52.0, ✓ `marketplace.json` 2.52.0 (intouchés par ce plan, cohérents)
  - ✓ badges/textes README.md et README.fr.md (version + nombre de modules)
  - ✓ triade par module (17 modules VERSION ↔ module.json alignés, `dev-orchestrator` inclus à
    v2.17.0)
  - ✓ historique en tête des deux README (v2.52.0)
  - ✓ en-têtes Version des 17 README de module (dev-orchestrator inclus)
  - ✗ `README.md` : compteur affiche « 55 suites » ≠ réel 61
  - ✗ `README.fr.md` : compteur affiche « 55 suites » ≠ réel 61
  - Verdict global : `rc=1` (dérive détectée) — **exactement les deux lignes tolérées** par le plan,
    rien d'autre en rouge.

**Passation nommée vers le plan 30-08** : le compteur de suites des deux README racine
(`README.md`, `README.fr.md`) affiche encore **55**, alors que le parc réel compte **61** — un écart
de +6, pas seulement le +1 de ce plan (plusieurs plans antérieurs de la Phase 30 ont déjà ajouté des
suites sans que ce compteur, propriété du plan `30-08` tâche 2, n'ait encore été mis à jour). Vérifié
au moment de cette tâche : le plan `30-08` n'a **pas encore joué sa tâche 2** (les deux README
affichent toujours 55, aucune valeur intermédiaire) — ceci est donc une **passation**, pas un
blocage humain. `30-08` doit compter **61**, pas 55, à son propre passage. Ni `README.md` ni
`README.fr.md` n'ont été modifiés par ce plan.

## Issues Encountered

Aucun autre problème que la déviation Rule 1 documentée ci-dessus (couplage T11/m3, corrigé avant
tout commit).

## Reliquats (consignés nommément, comme prescrit par le plan)

1. **Dette de doctrine — ADR-071 ne documente pas la dérogation de l'entrée n°26.** Le parc porte
   désormais une entrée exec dont le `command` est un nom nu, autorisée par l'**approbation humaine
   de l'addendum du 2026-08-15**. ADR-071 §Décision 2 exige l'inverse **sans clause d'exception** ;
   sa section « Ce que cette ADR ne tranche pas » ne mentionne pas ce cas ; son « Déclencheur de
   réexamen » vise la migration de la polarité gouvernance (cas d'un blocage par code de sortie),
   **pas celui-ci**. Un **amendement d'ADR-071 — ou une ADR dédiée — est dû** pour fermer l'écart ;
   `docs/ADR.md` est hors périmètre de ce plan (geste humain). Cette formulation **remplace et
   absorbe** l'ancien reliquat « amendement d'ADR-071 au titre du déclencheur activé » : le
   déclencheur n'est pas activé — c'est la doctrine qui est muette, ce qui est le vrai motif.
2. **Complétion de la liste des consommateurs** du bloc localisateur dans la suite amont de la lib
   (`plugin/_internal/tests/test-vf-portable.sh`, T12 — 3 consommateurs en dur : `guard-file-size.sh`,
   `inject-mcp-tools.sh`, `test-dev-orchestrator.sh`). `check-hook-paths.sh` est un 4e consommateur
   réel du bloc canonique (identité vérifiée localement par T10 de ce plan, contre
   `inject-mcp-tools.sh`), mais `plugin/_internal/` est hors périmètre de ce plan — la liste amont
   n'est donc PAS mise à jour ici (A-30-09-4, `30-CONTEXT.md`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Le plan `30-08` peut s'exécuter : ce plan (`30-09`) s'exécute bien AVANT sa tâche 2, comme exigé
  par l'ordonnancement du plan — le compteur de suites des deux README racine reste à mettre à jour
  vers 61, pas 55, sans autre édition requise côté `30-09`.
- Le module `dev-orchestrator` est en v2.17.0, cohérent avec `check-version-sync.sh` (triade et
  en-tête README verts).
- Deux reliquats nommés ci-dessus restent ouverts pour un geste humain futur (amendement ADR-071 ;
  complétion de la liste des consommateurs de `test-vf-portable.sh`).

## Self-Check: PASSED

- All 8 created/modified files verified present on disk.
- All 4 commit hashes (`dae62ec`, `dc37e07`, `2c638f2`, `e1c88bb`) verified present in `git log --oneline --all`.

---
*Phase: VFDO-30-portabilit-windows-ii*
*Completed: 2026-08-15*
