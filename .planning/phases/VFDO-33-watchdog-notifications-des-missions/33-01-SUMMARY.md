---
phase: 33-watchdog-notifications-des-missions
plan: 01
subsystem: infra
tags: [bash, driver-lock, adr-053, adr-064, d-33-a, wtch-01]

requires: []
provides:
  - "progress_epoch additif sur le meta du driver-lock — même patron ADR-064 que session_ids (32-01) : écrit à new_generation() à la même valeur que heartbeat_epoch, préservé par rewrite_meta() (3e paramètre positionnel optionnel) sauf appel explicite qui le fait avancer"
  - "verbe mark-progress --owner=<id> : avance progress_epoch SANS jamais toucher heartbeat_epoch, préserve step/branch/worktree/acquired_epoch au caractère près (garde [ -z \"$STEP\" ] && STEP=\"$(meta_get step)\")"
  - "progress_age() : même patron que lease_age(), donnée brute exposée pour le détecteur de stall (33-03) — jamais un jugement de seuil"
  - "json_status() étendu de progress_epoch/progress_age_seconds, null en rétrocompat (lock d'un ancien script)"
affects: [33-02, 33-03]

actuals:
  tokens: 6300
  tasks: 1
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Deuxième horloge additive sur le même meta (D-33-A) : même triptyque que session_ids en 32-01 — écrite à l'acquisition, préservée par défaut à la réécriture, avancée UNIQUEMENT par le verbe dédié qui passe le 3e argument explicitement"
    - "TDD RED/GREEN respecté à la lettre du task tdd=\"true\" : tests T51-T58 écrits et committés en rouge (16 FAIL mesurés) AVANT l'implémentation, puis GREEN (183 PASS / 0 FAIL)"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/driver-lock.sh
    - plugin/conductor/scripts/tests/test-driver-lock.sh

key-decisions:
  - "T19.1 (pré-existante, Phase 32) durcit un compte de lignes littéral du meta (8) — devient 9 avec le champ additif progress_epoch. Corrigé (8→9) comme conséquence directe et prévisible de ce plan (même évolution que 32-01 était passée de 7 à 8 avec session_ids), documenté ci-dessous en Déviations plutôt que silencieusement recalé."
  - "WTCH-01/QUAL-01 restent partagés par plusieurs plans frères de cette même phase (33-02/03 pour WTCH-01, transverse pour QUAL-01) — REQUIREMENTS.md non touché ici : ce plan s'exécute en worktree isolé (mode parallèle), les mises à jour STATE.md/ROADMAP.md/REQUIREMENTS.md sont explicitement du ressort du manager après intégration (mandat, périmètre strict)."

patterns-established:
  - "Toute mutation destructive sur driver-lock.sh committée AVANT d'être appliquée (leçon Phase 32 respectée à la lettre) : GREEN committé (fee117e) avant les 3 mutations rouges, chacune restaurée par git checkout -- vers un état déjà sain."

requirements-completed: []

coverage:
  - id: D1
    description: "progress_epoch additif : écrit à l'acquisition (symétrie avec heartbeat_epoch), préservé au heartbeat/reclaim, avancé exclusivement par mark-progress"
    requirement: "WTCH-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T51,T58"
        status: pass
    human_judgment: false
  - id: D2
    description: "mark-progress ne réécrit jamais heartbeat_epoch, préserve step/branch/worktree/acquired_epoch au caractère près — prouvé par 2 mutations rouges (heartbeat_epoch écrasé, garde step retirée)"
    requirement: "WTCH-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T52-T54"
        status: pass
    human_judgment: false
  - id: D3
    description: "cas « vivant mais bouclant » (heartbeat frais, progrès figé) observable en un seul appel status — critère de succès n°2 du plan"
    requirement: "WTCH-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T57"
        status: pass
    human_judgment: false
  - id: D4
    description: "rétrocompatibilité : lock d'un ancien script (meta sans progress_epoch) reste géré par tous les verbes, jamais un crash"
    requirement: "WTCH-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T56"
        status: pass
    human_judgment: false
  - id: D5
    description: "non-régression complète du dépôt (64 suites test-*.sh sous plugin/ et scripts/), aucune régression"
    verification:
      - kind: other
        ref: "find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l = 64, 64/64 exécutées vertes"
        status: pass
    human_judgment: false

duration: n/d (exécution inline en contexte vf-coder, hors chaîne de mesure horodatée de gsd-executor)
completed: 2026-08-17
status: complete
---

# Phase 33 Plan 01: progress_epoch + verbe mark-progress (D-33-A) Summary

**`driver-lock.sh` gagne une deuxième horloge additive, `progress_epoch`, et le verbe `mark-progress` qui l'avance sans jamais toucher `heartbeat_epoch` ni effacer `step` — le cas « vivant mais bouclant » (heartbeat frais, progrès figé) est désormais observable en un seul appel `status`, prouvé par 8 cas de test (T51-T58) et 3 mutations rouges.**

## Performance

- **Duration:** non mesurée avec précision (exécution inline en contexte `vf-coder`, worktree isolé)
- **Tasks:** 1/1 (tâche tracer, `tdd="true"`)
- **Files modified:** 2 (`driver-lock.sh`, `test-driver-lock.sh`)
- **Commits:** 2 (RED puis GREEN, cycle TDD explicite)

## Accomplishments

- `progress_age()` : nouvelle fonction, même patron que `lease_age()` — garde de numéricité, jamais un `0` trompeur, donnée brute exposée pour le détecteur de stall (plan 33-03), aucun seuil décidé ici.
- `new_generation()` : écrit `progress_epoch` à la MÊME valeur que `heartbeat_epoch` (symétrie de départ).
- `rewrite_meta()` : 3e paramètre positionnel optionnel `pe="${3-$(meta_get progress_epoch)}"`, même patron exact que `session_ids` en 32-01 — absent → préservation depuis le fichier, donc `heartbeat`/`reclaim` préservent `progress_epoch` sans le savoir.
- `json_status()` : deux clés `progress_epoch`/`progress_age_seconds`, `null` en rétrocompat.
- Verbe `mark-progress --owner=<id>` : avance `progress_epoch` en appelant `rewrite_meta "$(meta_get heartbeat_epoch)" "$(lock_session_ids)" "$ts"` — les deux premiers arguments RELUS du fichier, inchangés, garantissant que `heartbeat_epoch` ne bouge jamais. Garde `[ -z "$STEP" ] && STEP="$(meta_get step)"` posée avant l'appel, même patron que `heartbeat`/`reclaim` — sans elle, `step` serait effacé au premier appel (bug reproduit deux fois par des vérificateurs indépendants selon le plan, et confirmé ici par la mutation n°3).
- 8 nouveaux cas (T51-T58) + helper `progress_backdate()` + garde anti-vert-à-vide d'épilogue.
- Cycle TDD respecté à la lettre (`tdd="true"`) : tests écrits et committés EN ROUGE en premier (16 assertions échouant faute d'implémentation), puis implémentation committée séparément.

## Task Commits

1. **RED — T51-T58 + helper + garde anti-vert-à-vide** — `f4a66d9` (test)
2. **GREEN — progress_epoch + mark-progress + correction T19.1** — `fee117e` (feat)

## Files Created/Modified
- `plugin/conductor/scripts/driver-lock.sh` — `progress_age()` (nouvelle fonction), `new_generation()`/`rewrite_meta()`/`json_status()` étendus, parseur d'arguments + bloc `case mark-progress)` + lignes d'usage
- `plugin/conductor/scripts/tests/test-driver-lock.sh` — T51-T58, helper `progress_backdate()`, garde anti-vert-à-vide d'épilogue, correction T19.1 (8→9 lignes)

## Decisions Made
- **`mark-progress` relit `heartbeat_epoch` et `session_ids` du fichier plutôt que de les recevoir en paramètres implicites** : c'est la ligne `rewrite_meta "$(meta_get heartbeat_epoch)" "$(lock_session_ids)" "$ts"`, et elle seule, qui garantit que le battement ne peut JAMAIS être réécrit par ce verbe — vérifié par mutation n°2 (remplacer le premier argument par `$ts` fait rougir T53.1 exactement).
- **T19.1 corrigé (8→9 lignes du meta), documenté comme déviation attendue** plutôt que silencieusement recalé : le compte littéral de lignes du meta est une conséquence directe et prévisible de l'ajout d'un champ additif, exactement le même type d'évolution que 32-01 avait produit (7→8 avec `session_ids`). Aucune ligne injectée par erreur, seul le total suit la croissance légitime du schéma.
- **`lock_age()`/TTL/`stale` non touchés** : vérifié machine (`sed -n '/^lock_age()/,/^}/p' | grep -c progress_epoch` = 0) — ce plan expose une donnée brute, il ne décide aucune péremption.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, conséquence directe du changement de schéma] T19.1 durcissait un compte de lignes littéral (8) devenu faux (9) après l'ajout de `progress_epoch`**
- **Found during:** vérification GREEN (première exécution complète après implémentation)
- **Issue:** `T19.1` (cas pré-existant de la Phase 32, teste l'assainissement contre l'injection) compare `wc -l` du meta à la constante littérale `8`. Le meta légitime porte désormais 9 champs (`progress_epoch` ajouté), donc `T19.1` rougissait bien que l'assainissement lui-même reste correct — le total de lignes suit la croissance du schéma, pas une régression de l'assainissement.
- **Fix:** Constante mise à jour de 8 à 9 dans `test-driver-lock.sh`, avec un commentaire explicite renvoyant à l'analogie 32-01 (7→8 avec `session_ids`).
- **Files modified:** `plugin/conductor/scripts/tests/test-driver-lock.sh`
- **Verification:** Suite complète re-passée verte (183 PASS / 0 FAIL) après correction ; T19.2-T19.4 (assainissement lui-même) restés verts sans changement tout du long, prouvant que seul le compte total était affecté.
- **Committed in:** `fee117e` (même commit GREEN, pas de commit séparé — correction collatérale directe du même changement de schéma)

---

**Total deviations:** 1 auto-fixée (conséquence directe et prévisible du schéma additif, pas un bug de conception).
**Impact on plan:** Aucun sur le comportement livré — la constante corrigée décrit fidèlement le nouveau schéma du meta, elle ne relâche aucune garantie de sécurité/assainissement.

## Issues Encountered
Aucun, hors la déviation ci-dessus.

## Traces de mutation (obligatoire, QUAL-01/D-33-A)

Committé AVANT toute mutation (leçon Phase 32 respectée : `git checkout --` efface le travail non commité) — GREEN committé dans `fee117e`, les trois mutations partent toutes de cet état sain et y reviennent après restauration.

### Mutation n°1 — retrait de la ligne `progress_epoch=%s` dans `rewrite_meta()`
- **Mutation appliquée :** suppression de `printf 'progress_epoch=%s\n' "$pe"` à l'intérieur de `rewrite_meta()`.
- **Assertions touchées et traces :**
  - `T52.5 — progress_age_seconds proche de 0 après mark-progress` — attendu `< 60`, obtenu `None` (progress_epoch vide → `progress_age()` échoue → `null` côté status, `None` côté parse JSON python).
  - `T57.2 — progress_age_seconds >= 9000` — attendu `>= 9000`, obtenu `None`.
  - `T58.1 — progress_epoch inchangé après heartbeat` — attendu `1786963616` (valeur avant heartbeat), obtenu chaîne vide.
- **Résultat :** 180 PASS / 3 FAIL (T52, T57, T58 rougissent ; les 180 autres cas — dont T51, T53, T54, T55, T56 — restent verts, ce qui cible précisément la préservation de `progress_epoch`, pas un chemin cassé ailleurs).
- **Restauration :** `git checkout -- plugin/conductor/scripts/driver-lock.sh` ; `diff` avec la copie de référence confirmé identique ; suite revérifiée verte (183 PASS / 0 FAIL).

### Mutation n°2 — `mark-progress` fait écrire `heartbeat_epoch` (sens inverse)
- **Mutation appliquée :** dans le bloc `mark-progress)`, `rewrite_meta "$(meta_get heartbeat_epoch)" "$(lock_session_ids)" "$ts"` remplacé par `rewrite_meta "$ts" "$(lock_session_ids)" "$ts"`.
- **Assertion touchée :** `T53.1 — heartbeat_epoch inchangé au caractère près`
- **Attendu :** `1786963674` (valeur avant `mark-progress`)
- **Obtenu (sous mutation) :** `1786963675` (heartbeat_epoch avancé d'une seconde — la preuve exacte que la mutation réécrit bien le battement)
- **Résultat :** 182 PASS / 1 FAIL — seul T53.1 rougit (T52, T54-T58 restent verts, dont T53.2-T53.6 qui testent step/branch/worktree/acquired_epoch : la mutation touche STRICTEMENT `heartbeat_epoch`, rien d'autre).
- **Restauration :** `git checkout --` ; diff identique confirmé ; suite revérifiée verte (183 PASS / 0 FAIL).

### Mutation n°3 — retrait de la garde `step` dans le bloc `mark-progress`
- **Mutation appliquée :** suppression de la ligne `[ -z "$STEP" ] && STEP="$(meta_get step)"` dans le bloc `mark-progress)`.
- **Assertions touchées et traces :**
  - `T53.2 — step préservé (=etape-42, garde meta_get step)` — attendu `etape-42`, obtenu chaîne vide.
  - `T53.3 — step inchangé au caractère près` — attendu `etape-42`, obtenu chaîne vide.
- **Résultat :** 181 PASS / 2 FAIL — seuls T53.2/T53.3 rougissent (T53.1/T53.4-T53.6 restent verts : la mutation touche STRICTEMENT `step`, ni `heartbeat_epoch`, ni `branch`/`worktree`/`acquired_epoch`).
- **Restauration :** `git checkout --` ; diff identique confirmé ; suite revérifiée verte (183 PASS / 0 FAIL).

### Preuve de la garde anti-vert-à-vide (épilogue)
- **Test à blanc :** corps de la suite (T0 à T58, lignes 113-850) temporairement retiré de `test-driver-lock.sh`, ne laissant que les helpers et l'épilogue.
- **Résultat obtenu :** `0 PASS / 0 FAIL`, puis `❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable`, exit 1.
- **Preuve établie :** l'épilogue seul, sans aucune assertion exécutée, refuse structurellement de sortir vert.
- **Restauration :** `git checkout --` ; diff identique confirmé ; suite revérifiée verte (183 PASS / 0 FAIL).

## Non-régression — découverte complète (mesurée APRÈS le dernier commit `fee117e`)

Pattern CI exact du mandat : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort`

- **Suites découvertes :** 64 (inchangé — ce plan étend `test-driver-lock.sh`, fichier déjà découvert, n'en ajoute ni n'en retire aucune)
- **Exécutées / vertes :** 64 / 64 — 0 FAIL, 0 TIMEOUT (budget 45s/suite)
- **`test-driver-lock.sh` avant/après ce plan :** 151 PASS / 0 FAIL (baseline mesurée avant toute édition) → **183 PASS / 0 FAIL** (151 historiques + 32 assertions neuves sur T51-T58, aucune disparue)
- Suites consommatrices explicitement requises par le plan, revérifiées individuellement après le commit final :
  - `test-check-branch-claim.sh` — 18 OK / 0 KO
  - `test-guard-driver-lock.sh` — 80 PASS / 0 FAIL

Note process : un premier run du parc complet (`timeout` indisponible sur ce poste, macOS sans coreutils) a nécessité un timeout manuel maison (process en arrière-plan + kill après budget) ; un run précédent resté orphelin en tâche de fond a produit des doublons dans le fichier de résultats intermédiaire, dédoublonnés avant analyse (`awk` : dernier statut connu par suite, un FAIL/TIMEOUT écrase toujours un OK). L'ensemble dédoublonné (64 chemins) a été confronté par `comm`/`diff` à la découverte canonique — ensembles identiques, aucune suite manquante ni orpheline.

## User Setup Required
None - aucune configuration de service externe requise.

## Next Phase Readiness
- `progress_epoch`/`mark-progress`/`progress_age_seconds` sont posés et testés — le plan 33-02 (`dag.sh mark`) peut shelle un appel à un verbe qui EXISTE, et le plan 33-03 (détecteur de stall) peut lire `progress_age_seconds` déjà exposé en JSON.
- `WTCH-01`/`QUAL-01` restent partagés par des plans frères non encore livrés dans cette même phase — non marqués `Complete` ici (ce plan s'exécute en worktree isolé, la synchronisation `REQUIREMENTS.md`/`STATE.md`/`ROADMAP.md` est du ressort du manager après intégration).
- Aucun blocage identifié pour 33-02/33-03.

---
*Phase: 33-watchdog-notifications-des-missions*
*Completed: 2026-08-17*
