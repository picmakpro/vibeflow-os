---
phase: 32-durcissement-du-driver-lock
plan: 01
subsystem: infra
tags: [bash, driver-lock, adr-053, adr-064, d-32-01, d-32-03]

requires: []
provides:
  - "session_ids additif (liste CSV) sur le meta du driver-lock, amorcé à l'acquisition avec CLAUDE_CODE_SESSION_ID, préservé au heartbeat (jamais réécrit par un autre contexte)"
  - "generation (lock_gen()) exposée en JSON via status et les deux sorties de succès d'acquire"
  - "lease_seconds exposée en JSON (status + acquire), calculée depuis acquired_epoch, strictement informationnelle"
  - "sanitize_session_id(), lock_session_ids(), json_session_ids(), lease_age() : 4 fonctions additives"
affects: [32-02, 32-03, 32-04, 32-06]

actuals:
  tokens: 4571
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Champ meta additif capturé à l'acquisition et PRÉSERVÉ (jamais relu depuis l'environnement) au heartbeat — même patron qu'ADR-064 (branch/worktree), désormais répété une 3e fois (session_ids)"
    - "Absence/valeur non numérique -> la fonction dérivée (lease_age) échoue et rend non nul, l'appelant émet `null` en JSON — jamais un 0 numérique trompeur"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/driver-lock.sh
    - plugin/conductor/scripts/tests/test-driver-lock.sh

key-decisions:
  - "sanitize_session_id() SUPPRIME les caractères hors [A-Za-z0-9._-] (tr -dc), ne les substitue pas — une substitution laisserait un caractère à la place d'une virgule injectée, qui resterait un séparateur potentiel dans la liste CSV"
  - "lease_seconds n'entre dans AUCUN calcul de péremption ni refus (D-32-01) — lock_age()/TTL/stale restent adossés au seul heartbeat_epoch, sans changement, prouvé par deux mutations qui rougissent"
  - "QUAL-01 et LOCK-01 restent 'Pending' dans REQUIREMENTS.md : gate ID partagé par des plans frères non encore livrés dans cette même phase (32-02/03/05/06 pour QUAL-01, 32-06 pour LOCK-01) — confirmé par `gsd_run query requirements.ready-ids` (0/2 prêts), pas marqué par erreur"

patterns-established:
  - "Un champ meta additif suit toujours le même triptyque : écrit à l'acquisition (new_generation), préservé (jamais relu depuis l'environnement) à la réécriture (rewrite_meta), exposé en JSON aux 3 mêmes points de sortie (status, acquire voie libre, acquire réentrant)"

requirements-completed: []

coverage:
  - id: D1
    description: "session_ids additif : amorcé à l'acquisition, préservé au heartbeat (ADR-064), exposé en JSON, assaini contre l'injection de séparateurs, rétrocompatible avec un lock de l'ancien script"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T15-T20"
        status: pass
    human_judgment: false
  - id: D2
    description: "generation (lock_gen()) exposée en JSON — jeton de fence pour LOCK-05 (plan 32-04)"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T15,T20"
        status: pass
    human_judgment: false
  - id: D3
    description: "lease_seconds observable, dissociée du battement, jamais une source de péremption — mission longue jamais volée pour ancienneté de lease"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T21-T25"
        status: pass
    human_judgment: false
  - id: D4
    description: "Non-régression complète du dépôt (62 suites test-*.sh sous plugin/ et scripts/) après le dernier commit du plan"
    verification:
      - kind: other
        ref: "find plugin scripts -type f -path '*/tests/test-*.sh' | sort — 62 suites, exécutées post-commit"
        status: pass
    human_judgment: false

duration: n/d (exécution inline, hors chaîne de mesure horodatée de gsd-executor)
completed: 2026-08-17
status: complete
---

# Phase 32 Plan 01: session_ids + generation + lease_seconds — préalables du driver-lock durci Summary

**`driver-lock.sh` expose désormais `session_ids` (liste préservée au heartbeat, ADR-064), `generation` (jeton de fence pour LOCK-05) et `lease_seconds` (observabilité pure, jamais une source de péremption) — 4 fonctions additives et 10 nouveaux cas de test (T15-T25), les deux propriétés de non-réécriture prouvées par 3 mutations rouges puis restaurées.**

## Performance

- **Duration:** non mesurée avec précision (exécution inline en contexte `vf-coder`, pas via `gsd-executor` métré — voir Déviations)
- **Tasks:** 2/2
- **Files modified:** 2 (`driver-lock.sh`, `test-driver-lock.sh`)
- **Commits:** 2 (un par tâche)

## Accomplishments
- Champ additif `session_ids` (D-32-03(a)) : amorcé à l'acquisition avec `$CLAUDE_CODE_SESSION_ID`, préservé tel quel au heartbeat (jamais relu depuis l'environnement dans `rewrite_meta()`), assaini par suppression (pas substitution) des caractères hors `[A-Za-z0-9._-]`.
- `generation` (`lock_gen()`, déjà calculée, jamais rendue) désormais lisible en JSON — préalable du jeton de fence LOCK-05 (plan 32-04).
- `lease_seconds` (D-32-01) : observabilité de la lease depuis `acquired_epoch`, strictement informationnelle. `lock_age()`/`TTL`/`stale` restent adossés au seul `heartbeat_epoch`, inchangés — une mission longue mais vivante ne peut jamais être volée pour son ancienneté (T23).
- Rétrocompatibilité prouvée à deux niveaux : un lock de l'ancien script (meta sans `session_ids` ni `acquired_epoch`) reste géré sans plantage, `session_ids` replie sur `[]`, `lease_seconds` replie sur `null` (jamais un `0` trompeur).
- 10 nouveaux cas (T15-T25), 3 nouveaux helpers de suite (`json_ok`, `meta_drop_key`, `lease_backdate`), zéro `sleep` — tous les cas de battement/lease passent par des epochs forgés.

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Tâche 1 : session_ids + generation exposée** - `3104898` (feat)
2. **Tâche 2 : LOCK-01 — lease_seconds observable** - `582f398` (feat)

_Note : SUMMARY.md commité séparément après ce document (métadonnées de plan)._

## Files Created/Modified
- `plugin/conductor/scripts/driver-lock.sh` — 4 fonctions additives (`sanitize_session_id`, `lock_session_ids`, `json_session_ids`, `lease_age`), `new_generation()`/`rewrite_meta()`/`json_status()`/les 2 sorties de succès d'`acquire` étendus
- `plugin/conductor/scripts/tests/test-driver-lock.sh` — T15-T25, helpers `json_ok`/`meta_drop_key`/`lease_backdate`, en-tête de commentaires mis à jour

## Decisions Made
- **`sanitize_session_id()` supprime, ne substitue pas** (`tr -dc` plutôt que `tr -c ... '_'`) : une substitution laisserait un caractère à la place d'une virgule injectée, qui resterait un séparateur potentiel dans la liste CSV. Preuve : T19 vérifie l'absence de tout séparateur (`,`/espace) dans la valeur assainie ET le nombre total de lignes du meta (8, aucune ligne injectée par un saut de ligne non filtré).
- **`lease_age()` échoue plutôt que d'émettre `0`** sur `acquired_epoch` absent/non numérique — l'appelant traduit l'échec en `null` JSON. Un `0` numérique se lirait faussement « lease posée à l'instant » ; `null` dit honnêtement « non déterminable » (T25).
- **QUAL-01 et LOCK-01 restent `Pending`** dans `.planning/REQUIREMENTS.md` : ce sont des IDs partagés par plusieurs plans de la même phase (LOCK-01 par 32-01+32-06 ; QUAL-01 par 32-01+32-02+32-03+32-05+32-06), et le premier plan à finir ne doit pas les faire basculer `Complete` avant que tous les plans déclarants aient produit leur SUMMARY (garde #2388 — shared-ID gate). Vérifié par `gsd_run query requirements.ready-ids` : `0/2 requirement(s) ready to mark complete`. Aucune écriture faite sur `REQUIREMENTS.md`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Incident de process, sans impact sur le code livré] `git checkout --` a effacé le Task 1 non commité pendant la preuve de mutation**
- **Found during:** Tâche 1, étape de mutation rouge prouvée
- **Issue:** Le plan demande `git checkout -- plugin/conductor/scripts/driver-lock.sh` pour restaurer après une mutation. Comme les changements de la Tâche 1 n'avaient pas encore été committés à ce moment (aucun commit intermédiaire prévu par le plan avant la preuve de mutation), `git checkout --` a restauré le fichier à l'état de `HEAD` — c'est-à-dire AVANT la Tâche 1, effaçant du même coup le code et pas seulement la mutation.
- **Fix:** Les 6 éditions de la Tâche 1 ont été rejouées à l'identique, puis la suite complète a été re-vérifiée verte (48 PASS / 0 FAIL) avant tout commit. Le commit de la Tâche 1 a ensuite été posé AVANT de démarrer les mutations de la Tâche 2, pour que tout `git checkout --` ultérieur restaure vers un point qui contient déjà le code sain, jamais vers le fichier vierge.
- **Files modified:** `plugin/conductor/scripts/driver-lock.sh` (rejeu identique, pas de divergence de contenu)
- **Verification:** Diff de la Tâche 1 identique avant/après le rejeu (`git diff --stat` : mêmes 46 insertions / 6 suppressions) ; suite verte à 48 PASS / 0 FAIL avant le commit `3104898`.
- **Committed in:** `3104898`

---

**Total deviations:** 1 auto-fixé (incident de process pendant l'exécution, sans impact sur le code livré — aucune ligne différente de ce que le plan prescrivait).
**Impact on plan:** Aucun — le code final est identique à ce que les 6 éditions de la Tâche 1 produisaient, simplement rejoué une seconde fois. La leçon retenue (committer avant toute mutation destructive de test) a été appliquée pour la Tâche 2, où les deux mutations ont été restaurées sans perte.

## Issues Encountered
Aucun, hors la déviation ci-dessus (qui est un incident de process, pas un problème de conception ou de code).

## Traces de mutation (obligatoire, QUAL-01)

### Tâche 1 — mutation sur `rewrite_meta()` (préservation de `session_ids`)
- **Mutation appliquée :** retrait de la ligne `printf 'session_ids=%s\n' "$si"` à l'intérieur de `rewrite_meta()` (ligne 168 au moment du test).
- **Assertion touchée :** `T16.1 — session_ids reste sess-alpha après heartbeat de sess-beta`
- **Attendu :** `"session_ids": ["sess-alpha"]`
- **Obtenu (sous mutation) :** `{"present": true, "owner": "A", "step": "t15", ..., "session_ids": []}`
- **Résultat :** 47 PASS / 1 FAIL — seul T16 rougit, les 47 autres cas restent verts (dont T15/T17-T20, ce qui prouve que le rouge cible précisément la préservation, pas un chemin cassé ailleurs).
- **Restauration :** rejeu des 6 éditions de la Tâche 1 (voir Déviations ci-dessus) ; suite revérifiée verte (48 PASS / 0 FAIL) avant le commit `3104898`.

### Tâche 2 — mutation (a) : `lock_age()` basculée sur `acquired_epoch`
- **Mutation appliquée :** `lock_age()` lit `meta_get acquired_epoch` au lieu de `meta_get heartbeat_epoch`.
- **Assertions touchées et traces :**
  - `T21.2 — age_seconds < 60` — attendu `< 60`, obtenu `5000`.
  - `T21.3 — stale false malgré la lease reculée` — attendu `"stale": false`, obtenu `"stale": true` (JSON complet : `age_seconds: 5000, ttl: 1800, stale: true, lease_seconds: 5000`).
  - `T22.2 — stale false` — même bascule, `"stale": true` obtenu.
  - `T23.1 — stale false malgré une lease de 999999s` — attendu `"stale": false`, obtenu `"stale": true` (`age_seconds: 999999`).
  - `T23.2 — acquire d'un AUTRE owner refusé (held)` — attendu `"reason": "held"`, obtenu `{"acquired": true, "owner": "OTHER", ..., "recovered": true, "previous_owner": "A"}` (le lock a été VOLÉ, la mutation recrée exactement le mode de défaillance que la phase existe pour fermer).
  - `T23.3 — exit 1` — attendu exit 1, obtenu exit 0.
- **Résultat :** 47 PASS / 14 FAIL (T21, T22, T23 rougissent en cascade ; T15-T20, T24-T25 et T1-T14 restent verts).
- **Restauration :** `lock_age()` restaurée sur `meta_get heartbeat_epoch` ; suite revérifiée verte (61 PASS / 0 FAIL).

### Tâche 2 — mutation (b) : `rewrite_meta()` ré-horodate `acquired_epoch`
- **Mutation appliquée :** `printf 'acquired_epoch=%s\n' "$ap"` remplacé par `printf 'acquired_epoch=%s\n' "$(now)"` dans `rewrite_meta()`.
- **Assertion touchée :** `T22.1 — lease_seconds toujours >= 5000 après heartbeat`
- **Attendu :** `>= 5000`
- **Obtenu (sous mutation) :** `0` (le heartbeat a remis la lease à zéro en ré-horodatant `acquired_epoch`)
- **Résultat :** 60 PASS / 1 FAIL — seul T22 rougit (T21 et T23 restent verts car ils ne passent pas par un `heartbeat` après le backdate, donc leur `acquired_epoch` n'est jamais ré-horodaté dans leur propre flux).
- **Restauration :** `rewrite_meta()` restaurée sur `"$ap"` ; suite revérifiée verte (61 PASS / 0 FAIL) et committée dans `582f398`.

## Non-régression — découverte complète (mesurée APRÈS le dernier commit `582f398`)

Pattern CI exact du mandat : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort`

- **Exécutées / total :** 62 / 62
- **Échecs :** 0
- Suites explicitement requises par le plan, toutes vertes individuellement : `test-driver-lock.sh` (61 PASS / 0 FAIL), `test-check-branch-claim.sh` (18 OK / 0 KO), `test-conductor.sh` (12 passés / 0 échoués).

## User Setup Required
None - aucune configuration de service externe requise.

## Next Phase Readiness
- `session_ids`, `generation` et `lease_seconds` sont posés et testés — le guard `PreToolUse` du plan 32-03 peut désormais comparer une session à un champ qui EXISTE, et le jeton de fence du plan 32-04 dispose d'une `generation` lisible en JSON.
- Wave 2 (plan 32-02, `depends_on: [32-01]`) peut démarrer : aucun blocage.
- `LOCK-01` et `QUAL-01` restent `Pending` dans `REQUIREMENTS.md` (gate partagé, non tous les plans déclarants livrés) — normal à ce stade, pas un manque de cette exécution.

---
*Phase: 32-durcissement-du-driver-lock*
*Completed: 2026-08-17*
