---
phase: VFDO-30-portabilit-windows-ii
plan: 04

subsystem: infra
tags: [bash, hooks, claude-code, exit-codes, windows-portability, dev-orchestrator]

requires:
  - phase: VFDO-30-01
    provides: décisions D-06/D-07/D-08 (contrat de sortie, périmètre de normalisation, inventaire faisant foi)
provides:
  - Inventaire machine recompté des 25 entrées de hook du dépôt (docs/HOOKS-CONTRAT-SORTIE.md), classées advisory/bloquante avec mécanisme de blocage
  - Contrat de sortie durable (traduction conditionnée --hook, discipline de flux SessionStart)
  - hook_exit() dans les 4 scripts dev-orchestrator — silence interne (3) traduit en 0 sous --hook, sans lanceur d'enveloppe
  - Suite de contrat de sortie (test-hook-exit-contract.sh) — stdout/stderr capturés séparément, discrimination par mutation prouvée
affects: [30-06, 30-07]

actuals:
  tokens: 13795
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Point de traduction unique et nommé (hook_exit) par script, conditionné au drapeau --hook, jamais un lanceur d'enveloppe (D-06)"
    - "Contrat de sortie à 3 lignes (0/non-nul/2 réservé) distinct du contrat interne de signaux (Phase 17, exit 3 = silence)"
    - "Fixtures de test entièrement sous mktemp -d, y compris un dépôt git jetable et un moteur GSD factice minimal — jamais l'état réel du dépôt qui exécute la suite"

key-files:
  created:
    - docs/HOOKS-CONTRAT-SORTIE.md
    - plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh
  modified:
    - docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md
    - plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh
    - plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh
    - plugin/dev-orchestrator/scripts/check-doc-drift.sh
    - plugin/dev-orchestrator/scripts/check-gsd-config.sh

key-decisions:
  - "L'inventaire machine complet fait apparaître 5 entrées bloquantes (pas les 2 attendues par les exemples illustratifs du plan) : 4 via décision JSON permissionDecision:deny (guard-agent-write.sh, guard-read-registres.sh, guard-bash-registres.sh, guard-file-size.sh) + 1 via code de sortie voulu (guard-planning-updated.sh, exit 2 sur Stop). Documenté intégralement dans HOOKS-CONTRAT-SORTIE.md §5 — correction factuelle (Rule 1), pas une divergence de scope."
  - "Suite de contrat de sortie NEUVE plutôt qu'extension de test-dev-orchestrator.sh — harness dédié (deux flux, deux fichiers) pour rester lisible comme la preuve d'un contrat."
  - "Les 20 entrées gouvernance restent classées (advisory/bloquante + codes atteignables) mais non normalisées côté script par ce plan — action déférée explicitement au plan 30-06, documentée par entrée dans l'inventaire."

requirements-completed: [PORT-03]

coverage:
  - id: D1
    description: "Inventaire machine des 25 entrées de hook, chacune classée advisory/bloquante explicitement, avec commande de recomptage qui échoue bruyamment sur écart"
    requirement: "PORT-03"
    verification:
      - kind: unit
        ref: "python3 -c \"...glob.glob('plugin/*/hooks/hooks.json')...assert n==25\""
        status: pass
    human_judgment: false
  - id: D2
    description: "4 scripts dev-orchestrator normalisés — hook_exit() traduit le silence interne (3) en 0 sous --hook uniquement, jamais de lanceur d'enveloppe, contrat CLI/tests intact"
    requirement: "PORT-03"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh (184 OK / 0 KO / 0 SKIP)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Suite de contrat de sortie dédiée — 32 cas, stdout/stderr capturés séparément, 3 mutations discriminantes jouées sur les 4 scripts"
    requirement: "PORT-03"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh (32 OK / 0 KO)"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-08-15
status: complete
---

# Phase VFDO-30 Plan 04: Codes de sortie des hooks — inventaire, normalisation, contrat de sortie prouvé Summary

**Inventaire machine des 25 entrées de hook (5 bloquantes, 20 advisory), traduction `hook_exit()` du
silence interne vers 0 sous `--hook` dans les 4 scripts dev-orchestrator, et suite de contrat de
sortie à 32 cas prouvant la discrimination par mutation sur les deux flux séparément.**

## Performance

- **Duration:** 55 min
- **Tasks:** 3/3
- **Files modified:** 7 (2 créés, 5 modifiés)

## Accomplishments

- `docs/HOOKS-CONTRAT-SORTIE.md` (nouveau, durable) : contrat de sortie à 3 lignes, règle de
  traduction conditionnée `--hook`, discipline de flux SessionStart, inventaire à 25 lignes recompté
  à la machine (conductor 6, consolidator 7, dev-orchestrator 4, infrastructure-audit 1,
  planning-core 6, software-architecture 1), classement advisory/bloquante explicite par entrée.
- Spec `2026-08-02-portabilite-windows-ii-design.md` (§3.3/§3.4) : tous les chiffres périmés (22
  entrées, 17 `|| true`, 18 gouvernance, 4 dev) remplacés par le recompte D-08 (25, 20, 20, 5) ;
  `grep -c '22 entrées'` rend désormais 0.
- 4 scripts dev-orchestrator normalisés : fonction `hook_exit()` identique dans les 4, déclarée
  après `say()`, routant chaque site de silence interne (`exit 3`) — traduction en 0 SEULEMENT sous
  `--hook`, sans toucher aux codes 0/64, sans lanceur d'enveloppe. En-têtes corrigés (l'affirmation
  « --hook ne change rien » était devenue fausse par construction).
- `plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh` (nouveau) : 32 cas, deux flux
  capturés dans deux fichiers distincts sous `mktemp -d`, jamais fusionnés (`2>&1` absent du
  fichier), 3 mutations discriminantes jouées contre les 4 scripts.

## Task Commits

1. **Tâche 1 : inventaire machine + contrat de sortie écrit** — `d8814e3` (docs)
2. **Tâche 2 : normaliser la sortie des 4 scripts dev** — `3549d60` (feat)
3. **Tâche 3 : suite de contrat de sortie** — `2dbcc86` (test)

_Note : aucun commit de métadonnées séparé — le mandat interdit toute modification de
`.planning/STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md`, la phase VFDO-30 n'étant pas terminée
(5 autres plans en cours en parallèle sur le même arbre)._

## Files Created/Modified

- `docs/HOOKS-CONTRAT-SORTIE.md` (créé) — contrat de sortie + inventaire des 25 entrées + commande de recomptage
- `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md` (modifié) — chiffres §3.3/§3.4 corrigés (D-08)
- `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` (modifié) — `hook_exit()` + 4 sites routés
- `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (modifié) — `hook_exit()` + 3 sites routés
- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (modifié) — `hook_exit()` + 3 sites routés
- `plugin/dev-orchestrator/scripts/check-gsd-config.sh` (modifié) — `hook_exit()` + 4 sites routés
- `plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh` (créé) — 32 cas, 3 mutations discriminantes

## Decisions Made

- **Classification bloquante corrigée à 5 entrées, pas 2.** Le plan citait `guard-file-size.sh`
  (bloque via JSON malgré exit 0) et `guard-planning-updated.sh` (bloque via exit 2, VOULU) comme
  « points de vigilance » — la lecture machine systématique des 21 scripts gouvernance imposée par
  la tâche 1 a révélé 3 guards PreToolUse supplémentaires bloquant par le MÊME mécanisme JSON
  (`guard-agent-write.sh`, `guard-read-registres.sh`, `guard-bash-registres.sh`, tous trois
  `permissionDecision: deny`, exit 0 systématique). Les 5 sont nommées avec leur mécanisme exact
  dans `docs/HOOKS-CONTRAT-SORTIE.md` §5 ; les deux « points de vigilance » du plan y sont mis en
  avant nommément comme demandé par les critères d'acceptation, avec la correction documentée juste
  après.
- **Suite de test NEUVE plutôt qu'extension.** Conforme à l'instruction du plan : un harness à deux
  flux distincts (jamais fusionnés) se serait dilué dans les 700+ lignes de
  `test-dev-orchestrator.sh` ; `test-hook-exit-contract.sh` reste lisible comme preuve d'un contrat
  isolé.
- **Une seule paire de patrons sed pour les 3 mutations, appliquée aux 4 scripts.** Les 4
  `hook_exit()` sont textuellement identiques (vérifié par `awk` au cadrage) — un unique jeu de
  patrons sed scopés à la fonction (`/^hook_exit()/,/^}/`) suffit à prouver la discrimination sur le
  parc entier plutôt que sur un seul script, sans dupliquer la logique de mutation 4 fois.
- **20 entrées gouvernance classées mais pas normalisées ici.** Conforme au découpage du plan
  (normalisation du reste du parc → 30-06 ; migration forme exec dev → 30-07) — chaque entrée porte
  déjà son classement complet et son action requise dans l'inventaire, pour que 30-06 n'ait pas à
  refaire la lecture.

## Preuve de discrimination par mutation (à citer, plan §Tâche 3)

Les 3 mutations ont été jouées contre les 4 scripts (12 cas), toutes rougissent avec la dimension
fautive nommée, puis restaurées immédiatement (mutants vivant uniquement sous `mktemp -d`, aucun
fichier du dépôt modifié par la suite elle-même) :

| Mutation | Ce qu'elle casse | Cas | Dimension fautive citée |
|---|---|---|---|
| **m1** — neutralise la condition `--hook` dans `hook_exit()` (`HOOK -eq 1` → `HOOK -eq 9`, jamais vraie) | Les 4 cas « silencieux avec `--hook` » (attendu code 0) | `MUTATION m1 (check-dev-bootstrap.sh)` et les 3 autres scripts | `code(attendu 0 — comportement correct —, obtenu 3 sous la mutation)` |
| **m2** — traduit 3→0 SANS condition de mode (retire le test `HOOK -eq 1`) | Les 4 cas de non-régression CLI « silencieux SANS `--hook` » (attendu code 3) | `MUTATION m2 (check-dev-bootstrap.sh)` et les 3 autres scripts | `code(attendu 3 — comportement correct —, obtenu 0 sous la mutation)` |
| **m3** — insère `echo "mutation-m3-leak"` avant le `exit 0` interne à `hook_exit()` | Les 4 cas « silencieux avec `--hook` » — sur la dimension STDOUT SEULE, le code reste bon | `MUTATION m3 (check-dev-bootstrap.sh)` et les 3 autres scripts | `stdout(attendu vide — comportement correct —, obtenu 17 octets sous la mutation)` — code toujours 0, preuve que la suite teste le FLUX et pas seulement le code |

Sortie brute de la suite (les 12 lignes de mutation, restituée telle quelle) :

```
m1 · check-dev-bootstrap.sh : code(attendu 0 — comportement correct —, obtenu 3 sous la mutation)
m2 · check-dev-bootstrap.sh : code(attendu 3 — comportement correct —, obtenu 0 sous la mutation)
m3 · check-dev-bootstrap.sh : stdout(attendu vide — comportement correct —, obtenu 17 octets sous la mutation)
m1 · discover-unintegrated-docs.sh : code(attendu 0 — comportement correct —, obtenu 3 sous la mutation)
m2 · discover-unintegrated-docs.sh : code(attendu 3 — comportement correct —, obtenu 0 sous la mutation)
m3 · discover-unintegrated-docs.sh : stdout(attendu vide — comportement correct —, obtenu 17 octets sous la mutation)
m1 · check-doc-drift.sh : code(attendu 0 — comportement correct —, obtenu 3 sous la mutation)
m2 · check-doc-drift.sh : code(attendu 3 — comportement correct —, obtenu 0 sous la mutation)
m3 · check-doc-drift.sh : stdout(attendu vide — comportement correct —, obtenu 17 octets sous la mutation)
m1 · check-gsd-config.sh : code(attendu 0 — comportement correct —, obtenu 3 sous la mutation)
m2 · check-gsd-config.sh : code(attendu 3 — comportement correct —, obtenu 0 sous la mutation)
m3 · check-gsd-config.sh : stdout(attendu vide — comportement correct —, obtenu 17 octets sous la mutation)
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug factuel] Correction du décompte des entrées bloquantes (2 → 5)**
- **Found during:** Tâche 1 (inventaire machine)
- **Issue:** Le plan citait `guard-file-size.sh` et `guard-planning-updated.sh` comme les « deux
  entrées bloquantes » (points de vigilance illustratifs). La lecture machine systématique des 21
  scripts gouvernance (imposée par l'action de la tâche 1) a montré que 3 autres guards
  `PreToolUse` (`guard-agent-write.sh`, `guard-read-registres.sh`, `guard-bash-registres.sh`)
  bloquent par le même mécanisme (`permissionDecision: deny`, exit 0 systématique) — non mentionnés
  par le plan, jamais audités avant cette phase (D-08 : « aucun audit préalable de légitimité des
  entrées apparues depuis la spec »).
- **Fix:** Les 5 entrées bloquantes sont nommées avec leur mécanisme exact dans
  `docs/HOOKS-CONTRAT-SORTIE.md` §5 ; les deux exemples du plan y sont mis en avant nommément (texte
  dédié « les deux entrées bloquantes mises en avant par le plan »), suivi de la liste complète.
- **Files modified:** `docs/HOOKS-CONTRAT-SORTIE.md`
- **Verification:** Relevé manuel de `permissionDecision.*deny` sur les 4 scripts PreToolUse
  concernés + `exit 2` sur `guard-planning-updated.sh` (Stop), croisé avec les 25 entrées de
  `hooks.json`.
- **Committed in:** `d8814e3` (tâche 1)

---

**Total deviations:** 1 auto-fixée (Rule 1 — correction factuelle de comptage, portée documentaire
seule, aucun changement de code ni de scope).
**Impact on plan:** Aucun — la correction rend l'inventaire exact pour Willy (héritier du document)
sans toucher au périmètre de code de cette phase.

## Issues Encountered

- `sed` sur macOS (BSD) refuse la syntaxe `{...}` de regroupement d'adresse (`/addr1/,/addr2/{s/.../.../}`)
  utilisée en premier essai pour les mutations — corrigé en `/addr1/,/addr2/ s/.../.../` (forme
  portable), validé manuellement avant intégration dans la suite (voir Bash de vérification).
- Outillage : conformément aux contraintes du mandat, tout dénombrement (`hook_exit`, `exit 3` brut,
  `run-hook`) est passé par `awk` plutôt que par `grep` proxifié — la première tentative via
  `grep -v ... | grep -cE ...` a produit une sortie tronquée/mal interprétée par le proxy `rtk`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `docs/HOOKS-CONTRAT-SORTIE.md` est prêt à être hérité par le plan 30-06 (normalisation des 20
  entrées gouvernance) : chaque entrée y porte déjà son classement, ses codes atteignables et
  l'action requise.
- Les 4 `hooks.json` de dev-orchestrator/software-architecture restent en forme shell — la migration
  en forme exec (plan 30-07) peut s'appuyer sur des scripts déjà normalisés côté silence.
- `guard-planning-updated.sh` est explicitement marqué « ne jamais normaliser » dans l'inventaire —
  30-06 n'a pas à re-découvrir cette contrainte.
- Aucun blocage : `.planning/STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md` n'ont pas été touchés
  (mandat), la mise à jour de progression de phase reste à la charge de l'orchestrateur de phase
  une fois les 6 plans de VFDO-30 réunis.

---
*Phase: VFDO-30-portabilit-windows-ii*
*Completed: 2026-08-15*

## Self-Check: PASSED

Tous les fichiers créés/modifiés existent sur disque, les 3 commits de tâche (`d8814e3`, `3549d60`, `2dbcc86`) sont vérifiés présents dans `git log --oneline --all`.
