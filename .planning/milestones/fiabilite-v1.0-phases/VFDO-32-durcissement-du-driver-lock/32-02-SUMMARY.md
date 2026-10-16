---
phase: 32-durcissement-du-driver-lock
plan: 02
subsystem: infra
tags: [bash, driver-lock, adr-053, d-32-02, d-32-03, gel-2, bl-3, bl-9, se-3, se-6]

requires:
  - phase: 32-01
    provides: "session_ids additif, generation exposée en JSON, lease_seconds observable — préalables partagés"
provides:
  - "acquire refuse (stale-requires-takeover) au lieu de voler un lock périmé — l'auto-steal implicite disparaît (LOCK-04)"
  - "verbe takeover (reprise explicite d'un lock PÉRIMÉ) : mutex nommé d'après la génération observée + double revalidation post-mutex (génération ET âge), trap de libération sous panne"
  - "verbe reclaim (re-rattachement d'une session neuve à un lock VIVANT dont on est déjà owner) : réutilise mot pour mot le mutex/la revalidation de takeover, plus contrôle d'owner, plus trap"
  - "session_ids_append() : plafond LRU (VF_DRIVER_SESSION_MAX, défaut 8) fermant la croissance non bornée laissée ouverte par D-32-03"
  - "garde d'existence GEL-2 (lock_present avant ln_atomic en voie libre) fermant le double-détenteur sur un lock LEGACY frais"
  - "journal_event() : journal append-only ${LOCK_BASE}.events.log, FRÈRE du lock, une ligne JSON par takeover/reclaim/recover réussi"
  - ".gitignore corrigé (BL-9) : motif SANS barre finale, couvre le chemin nominal (lien) ET ses frères"
affects: [32-03, 32-04, 32-05, 32-06]

actuals:
  tokens: 12096
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Un geste de reprise (takeover) et un geste de re-rattachement (reclaim) partagent MOT POUR MOT le même patron de mutex + double revalidation post-mutex — jamais un second patron de concurrence inventé"
    - "Seam de test env-gated, inerte par défaut (VF_DRIVER_TEST_DIE_AFTER_MUTEX) pour prouver un trap de manière déterministe — un SIGTERM/SIGINT réel n'est PAS fiable pour ça (bash reprend l'exécution après un trap qui n'appelle pas exit, vérifié empiriquement)"
    - "Fixture propre par cas de test (BL-4) : jamais l'état laissé par un cas voisin, pour qu'un renversement d'assertion ne fasse pas rougir un cas non prévu en silence"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/driver-lock.sh
    - plugin/conductor/scripts/tests/test-driver-lock.sh
    - .gitignore

key-decisions:
  - "GEL-2 : garde `lock_present()` (couvre `-L` ET `-d`) posée AVANT `ln_atomic` en voie libre d'acquire — ferme un double-détenteur mesuré sur un lock legacy (dossier réel) frais, sans rouvrir le protocole de reprise"
  - "reclaim réutilise EXACTEMENT le mutex/la revalidation de takeover (D-32-03(f)) — le contrôle d'owner s'ajoute car reclaim s'applique à un lock VIVANT dont l'owner peut changer pendant la fenêtre"
  - "SE-3 : rewrite_meta() gagne un second paramètre positionnel OPTIONNEL (`${2-$(lock_session_ids)}`, pas `${2:-...}`) — les deux appelants historiques à un seul argument continuent sans modification, seul reclaim passe la valeur décidée sous mutex"
  - "T45 : la panne du plan visait le « répertoire parent » rendu non inscriptible — vérifié IMPOSSIBLE sous POSIX sans AUSSI casser l'unlink que fait drop_lock (supprimer une entrée de répertoire exige le droit d'écriture sur CE répertoire, pas sur l'entrée). La panne cible donc le FICHIER journal lui-même (chmod 444), isolant le canal sans toucher à la capacité de recover à élaguer le lock — déviation disclosée dans le commit cc36f86"
  - "Mutation (b) de la tâche 1 (retrait de la revalidation d'âge dans takeover) NE fait PAS rougir T32 tel que littéralement spécifié par le plan — 13 passes empiriques restées vertes. Cause structurelle : les 24 concurrents de T32 partagent tous la MÊME génération observée au départ, donc le MÊME nom de mutex — un seul peut jamais franchir `ln_atomic`, quel que soit l'état de la revalidation d'âge. Le bug que cette revalidation ferme est une course à DEUX étages (un retardataire dont la lecture d'âge et la lecture de génération encadrent la fin d'un AUTRE gagnant), que T32 ne peut pas provoquer par construction. Prouvé par reproduction ciblée déterministe (fenêtre élargie localement, JAMAIS committée) plutôt que par la lettre de T32 — voir Traces de mutation ci-dessous"
  - "T41b.2 testait `-e` sur le mutex (un lien cassé — `ln_atomic` le pointe vers un PID nu, jamais un chemin existant) : `-e` suit le lien et le trouve toujours cassé, faux positif garanti. Corrigé en `-L` (commit 00ae34f), détecté en vérifiant la mutation (d) de la tâche 2"

patterns-established:
  - "Un refus de lock PÉRIMÉ porte toujours un champ `hint` nommant la commande exacte de reprise — c'est le seul canal qui atteint un appelant sans le toucher"
  - "session_ids ne se purge QUE dans reclaim (via session_ids_append) — takeover n'a besoin d'aucune purge, sa generation neuve réduit structurellement la liste au seul repreneur"

requirements-completed: []

coverage:
  - id: D1
    description: "acquire refuse (stale-requires-takeover, hint) au lieu de voler un lock périmé — LOCK-04"
    requirement: "LOCK-04"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T7,T13,T26"
        status: pass
    human_judgment: false
  - id: D2
    description: "takeover reprend explicitement un lock périmé, exclusion mutuelle prouvée 24×5 (jamais 2, jamais 0), trap de libération du mutex sous panne"
    requirement: "LOCK-04"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T27-T32,T33-legacy"
        status: pass
    human_judgment: false
  - id: D3
    description: "GEL-2 : garde d'existence en voie libre ferme le double-détenteur sur lock legacy frais"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T0,T12.2"
        status: pass
    human_judgment: false
  - id: D4
    description: "reclaim re-rattache une session neuve à un lock vivant, mutex partagé avec takeover, plafond LRU de session_ids, ne prolonge pas la fraîcheur, trap sous panne (BL-3, cas nominal)"
    requirement: "LOCK-04"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T33-T41,T41b"
        status: pass
    human_judgment: false
  - id: D5
    description: "Journal append-only des reprises, survit à la destruction de la génération, best-effort (ne bloque jamais le verrou)"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-driver-lock.sh#T42-T45"
        status: pass
    human_judgment: false
  - id: D6
    description: ".gitignore corrigé (BL-9) : couvre le chemin nominal (lien) ET ses frères"
    verification:
      - kind: other
        ref: "git status --porcelain -- '.planning/DRIVER.lock*' strictement vide après cycle acquire/recover réel (probe .gitignoretest)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Non-régression complète du dépôt (62 suites test-*.sh sous plugin/ et scripts/) après le dernier commit du plan"
    verification:
      - kind: other
        ref: "find plugin scripts -type f -path '*/tests/test-*.sh' | sort — 62 suites, exécutées post-commit cc36f86"
        status: pass
    human_judgment: false

duration: n/d (exécution inline, hors chaîne de mesure horodatée de gsd-executor)
completed: 2026-08-17
status: complete
---

# Phase 32 Plan 02: takeover explicite, reclaim, journal, GEL-2 — Summary

**`acquire` ne vole plus jamais un lock périmé : il refuse en nommant `takeover`, qui reprend avec l'exclusion mutuelle mesurée intacte (24×5, jamais 2, jamais 0) ; `reclaim` re-rattache une session neuve à un lock vivant par le MÊME mutex ; les deux libèrent leur mutex même sous panne (trap, BL-3) ; un journal append-only trace toutes les reprises ; et un trou de la voie legacy mesuré le 2026-08-17 (double-détenteur) est fermé (GEL-2).**

## Performance

- **Duration:** non mesurée avec précision (exécution inline en contexte `vf-coder`, pas via `gsd-executor` métré)
- **Tasks:** 3/3
- **Files modified:** 3 (`driver-lock.sh`, `test-driver-lock.sh`, `.gitignore`)
- **Commits:** 4 (3 tâches + 1 correction de test)

## Accomplishments

- **Tâche 1** : GEL-2 (garde `lock_present` avant `ln_atomic` en voie libre), `acquire` refuse `stale-requires-takeover` (avec `hint`) au lieu de récupérer implicitement, verbe `takeover` (mutex nommé d'après la génération observée, double revalidation génération+âge, trap `EXIT INT TERM`). 19 cas neufs/renversés : T0, T7 renversé, T8 découplé de T7 (BL-4), T12.2 adapté au bug GEL-2, T13 adapté (0 gagnant), T26-T32, T33-legacy (SE-6).
- **Tâche 2** : verbe `reclaim` (D-32-03(f)) — réutilise mot pour mot le mutex/la revalidation de `takeover`, plus contrôle d'owner, plus le MÊME trap (BL-3, cas nominal ici : la génération est vivante et durable, pas détruite par la reprise). `session_ids_append()` avec plafond LRU (`VF_DRIVER_SESSION_MAX`, défaut 8). `rewrite_meta()` gagne un second paramètre optionnel (SE-3, `${2-...}`) sans casser les deux appelants historiques. 9 cas neufs (T33-T41, T41b) + seam de test dédié (`VF_DRIVER_TEST_DIE_AFTER_MUTEX`, inerte par défaut).
- **Tâche 3** : `journal_event()` — journal append-only `${LOCK_BASE}.events.log`, frère du lock, une ligne JSON par takeover/reclaim/recover réussi, best-effort (jamais bloquant). `.gitignore` corrigé (BL-9) : `.planning/DRIVER.lock*` sans barre finale couvre le chemin nominal (lien) ET ses frères. 4 cas neufs (T42-T45).
- **Correction hors plan** : `T41b.2` testait `-e` sur le mutex (lien cassé par construction) — faux positif garanti, corrigé en `-L` (commit `00ae34f`), détecté en vérifiant la mutation (d) de la tâche 2.

## Task Commits

1. **Tâche 1 : acquire refuse + takeover** — `b1ab1df` (feat)
2. **Tâche 2 : reclaim + plafond LRU** — `d05ac33` (feat)
3. **Correction T41b.2 (`-e` → `-L`)** — `00ae34f` (fix, hors plan, découverte en vérifiant la mutation d)
4. **Tâche 3 : journal + gitignore** — `cc36f86` (feat)

## Files Created/Modified

- `plugin/conductor/scripts/driver-lock.sh` — verbes `takeover`/`reclaim`, `session_ids_append()`, `journal_event()`, garde GEL-2, traps BL-3, seam de test `VF_DRIVER_TEST_DIE_AFTER_MUTEX`
- `plugin/conductor/scripts/tests/test-driver-lock.sh` — T0, T26-T45, T33-legacy, T41b ; T7/T8/T12/T13 renversés ou adaptés
- `.gitignore` — motif `.planning/DRIVER.lock*` (BL-9)

## Decisions Made

Voir `key-decisions` en frontmatter (GEL-2, réutilisation stricte du mutex par `reclaim`, SE-3, déviation T45, non-rougissement de la mutation (b) sur T32 tel que littéralement spécifié, correction `-e`→`-L`).

## Deviations from Plan

### Auto-fixed / disclosed

**1. T45 : panne injectée sur le fichier journal, pas sur le « répertoire parent »**
- **Found during:** Tâche 3, conception du cas de panne injectée
- **Issue:** Le plan demande de rendre le répertoire parent (`$LOCK_PARENT`) non inscriptible pendant un `recover`, et d'attester que `recover` réussit quand même. Vérifié empiriquement (`chmod 555` sur un dossier test, `rm -f` d'un fichier dedans) : sous POSIX, supprimer une entrée de répertoire exige le droit d'écriture sur LE RÉPERTOIRE lui-même, jamais sur l'entrée — rendre `$LOCK_PARENT` non inscriptible bloquerait donc AUSSI l'unlink que fait `drop_lock`, rendant la combinaison « répertoire non inscriptible » + « recover réussit quand même » structurellement impossible.
- **Fix:** La panne cible le FICHIER journal lui-même (pré-créé, `chmod 444`), isolant le canal de journalisation sans toucher à la capacité de `drop_lock` à élaguer le lock. Satisfait la lettre du critère (recover réussit, diagnostic sur stderr, permissions restaurées) sans la contradiction POSIX.
- **Verification:** T45.1-T45.3 verts ; mutation (c) (échec d'écriture rendu fatal) rougit T45.1/T45.2, prouvant que le cas teste bien un vrai chemin dégradé.
- **Committed in:** `cc36f86` (documenté en commentaire dans le commit)

**2. Mutation (b) de la tâche 1 ne rougit pas T32 tel que littéralement spécifié**
- **Found during:** Tâche 1, preuve de mutation rouge exigée par l'acceptance criteria
- **Issue:** Retirer la revalidation d'âge post-mutex de `takeover` (ne garder que la génération) devait, selon le plan, rendre T32 rouge sur au moins un round des cinq. Empiriquement : 13 passes de la suite complète (65 rounds × 24 concurrents) sont restées vertes sous cette mutation.
- **Analyse :** T32 lance ses 24 concurrents depuis la MÊME génération observée au départ — ils partagent donc tous le MÊME nom de mutex, et `ln_atomic` (atomique) ne laisse jamais passer plus d'un seul d'entre eux, indépendamment de la revalidation d'âge. Le bug que cette revalidation ferme est une course à DEUX ÉTAGES : un retardataire dont la lecture d'âge précède la fin d'un AUTRE gagnant et dont la lecture de génération la suit, obtenant alors un mutex libre sur la génération NEUVE (jamais contestée) et volant un lock qui vient d'être légitimement acquis. Cette interleaving à deux étages n'existe pas dans T32 par construction (tous démarrent simultanément depuis un état stale unique, aucun gagnant précédent à l'intérieur d'un même round).
- **Fix:** Reproduction ciblée déterministe (fenêtre élargie via un hook local temporaire, jamais committé) : un process STRAGGLER lit l'âge puis dort 0.2s (fenêtre forcée) avant de lire la génération, pendant qu'un process WINNER rapide fait un takeover complet. Sous la mutation, les DEUX obtiennent `"acquired": true` (double détenteur, la STRAGGLER volant le lock frais de WINNER). Sous le code sain (revalidation d'âge présente), WINNER seul réussit, STRAGGLER reçoit `race-during-recovery`. Cette preuve directe remplace la preuve par T32, qui ne peut structurellement pas exercer ce chemin.
- **Verification:** Reproduction rejouée deux fois (mutation → rouge confirmé ; code sain → vert confirmé), traces complètes ci-dessous.
- **Committed in:** aucun commit — reproduction locale uniquement, jamais intégrée au fichier livré (le hook temporaire a été retiré avant tout commit).

---

**Total deviations:** 2 disclosées, aucune ne change le comportement livré ni l'exigence de preuve — la première adapte la cible de la panne injectée à une contrainte POSIX réelle, la seconde remplace une preuve structurellement impossible par une preuve directe équivalente.

## Issues Encountered

Aucun autre, hors les deux déviations ci-dessus.

## Traces de mutation (obligatoire, QUAL-01)

### Tâche 1 — mutation (a) : auto-recovery rétablie dans `acquire`
- **Mutation appliquée :** le bloc « 3. PERIME » d'`acquire` recrée le comportement d'avant-phase (`"acquired": true, "recovered": true`) au lieu de refuser.
- **Assertions touchées :** `T7.1` (attendu `"acquired": false`, obtenu `true`), `T13.1` (attendu 0 hors-contrat, obtenu 10 rounds hors-contrat).
- **Résultat :** 81 PASS / 7 FAIL.
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte (88 PASS / 0 FAIL) avant le commit `b1ab1df`.

### Tâche 1 — mutation (b) : revalidation d'âge retirée de `takeover` (voir Déviations ci-dessus pour l'analyse complète)
- **Mutation appliquée :** `if [ "$(lock_gen)" != "$observed_gen" ]; then` (âge retiré du test).
- **T32 : resté vert sur 13 passes empiriques (65 rounds)** — non-rougissement analysé et expliqué dans les Déviations.
- **Reproduction directe :** straggler (`sleep 0.2` forcé entre lecture d'âge et lecture de génération) + winner rapide concurrent.
  - **Sous mutation :** `winner.out = {"acquired": true, "owner": "WINNER", ...}` ET `straggler.out = {"acquired": true, "owner": "STRAGGLER", ...}` — DEUX détenteurs, `status` final montre `"owner": "STRAGGLER"` (vol du lock de WINNER).
  - **Code sain :** `winner.out = {"acquired": true, "owner": "WINNER", ...}`, `straggler.out = {"acquired": false, "reason": "race-during-recovery"}` — UN SEUL détenteur.
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte (88 PASS / 0 FAIL) avant le commit `b1ab1df`.

### Tâche 1 — mutation (c) : garde `lock_present` (GEL-2) retirée de la voie libre
- **Mutation appliquée :** `if ln_atomic "$gen" "$LOCK_DIR"; then` (garde retirée).
- **Assertions touchées :** `T0.1` (attendu `false`, obtenu `{"acquired": true, "owner": "bob", ..., "generation": "legacy", ...}`), `T0.2`, `T12.2a` (attendu `stale-requires-takeover`, obtenu `{"acquired": true, "owner": "NEW", ...}`), `T12.2b`.
- **Résultat :** 80 PASS / 8 FAIL.
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte (88 PASS / 0 FAIL) avant le commit `b1ab1df`.

### Tâche 2 — mutation (a) : mutex de `reclaim` retiré (écriture directe)
- **Mutation appliquée :** `mutex=...; true` remplace `mutex=...; if ! ln_atomic ...`.
- **Assertion touchée :** `T40.3` — attendu `0` identifiant perdu, obtenu `11` (sur 12 succès rapportés, 11 identifiants absents de la liste finale — écritures concurrentes non sérialisées, la plupart perdues).
- **Résultat :** reproduit 5/5 passes (dès la 1ère).
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte (116 PASS / 0 FAIL) avant le commit `d05ac33`.

### Tâche 2 — mutation (b) : plafond LRU retiré
- **Mutation appliquée :** `session_ids_append()` rend la liste complète, sans troncature.
- **Assertions touchées :** `T39.1` (attendu 8, obtenu 11), `T39.3` (le plus ancien n'a pas été évincé).
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte avant le commit `d05ac33`.

### Tâche 2 — mutation (c) : `reclaim` ré-horodate `heartbeat_epoch`
- **Mutation appliquée :** `hb="$(now)"` remplace `hb="$(meta_get heartbeat_epoch)"`.
- **Assertion touchée :** `T41.1` — attendu `age_seconds >= 890`, obtenu `0`.
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte avant le commit `d05ac33`.

### Tâche 2 — mutation (d) : trap de `reclaim` retiré (BL-3)
- **Mutation appliquée :** `trap 'rm -f "$mutex"' EXIT INT TERM` remplacé par `true`.
- **Assertions touchées :** `T41b.2` (mutex resté présent, `-L` vrai), `T41b.3` (attendu `"reclaimed": true`, obtenu `{"reclaimed": false, "reason": "race-during-reclaim"}`), `T41b.4` (exit 1 au lieu de 0).
- **Reproduit une seconde fois EN DIRECT pendant la revue du manager** (2026-08-17), après correction `-e`→`-L` : mêmes trois assertions rouges, confirmées puis restaurées.
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte (132 PASS / 0 FAIL) après chaque passe.

### Tâche 3 — mutation (a) : journal déplacé dans le dossier de génération
- **Mutation appliquée :** `log_path="$LOCK_DIR/events.log"` remplace `log_path="$LOCK_PARENT/${LOCK_BASE}.events.log"`.
- **Assertion touchée :** `T43.1` — le journal n'existe plus après la destruction de la génération (`No such file or directory`), cascade sur T44.
- **Résultat :** 119 PASS / 13 FAIL.
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte avant le commit `cc36f86`.

### Tâche 3 — mutation (b) : append remplacé par écrasement
- **Mutation appliquée :** `>> "$log_path"` remplacé par `> "$log_path"`.
- **Assertion touchée :** `T44.1` — attendu 3 lignes, obtenu 1 (seul le dernier événement `recover` survit, `takeover` et `reclaim` écrasés).
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte avant le commit `cc36f86`.

### Tâche 3 — mutation (c) : échec d'écriture du journal rendu fatal
- **Mutation appliquée :** `|| { log ...; exit 1; }` remplace le message diagnostique best-effort.
- **Assertions touchées :** `T45.1` (attendu `"recovered": true`, obtenu vide — le process a quitté avant d'émettre le JSON), `T45.2` (exit 1 au lieu de 0).
- **Restauration :** `git checkout -- driver-lock.sh` ; suite revérifiée verte (132 PASS / 0 FAIL) avant le commit `cc36f86`.

## Non-régression — découverte complète (mesurée APRÈS le dernier commit `cc36f86`)

Pattern CI exact du mandat : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort`

- **Exécutées / total :** 62 / 62
- **Échecs :** 0
- Suites explicitement requises par le plan, toutes vertes individuellement : `test-driver-lock.sh` (132 PASS / 0 FAIL), `test-check-branch-claim.sh` (18 OK / 0 KO), `test-conductor.sh` (0 échec), `check-machine-paths.sh` (0 chemin machine, exit 0).
- Sonde `.gitignore` scopée (BL-8, jamais `.planning/` en entier) : `git status --porcelain -- '.planning/DRIVER.lock*'` strictement vide après un cycle `acquire`/`recover` réel sur un chemin de probe distinct (jamais le vrai `.planning/DRIVER.lock`, verrouillé par la mission).

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- LOCK-04 est servi : `acquire` ne vole plus, `takeover`/`reclaim` sont les deux seuls gestes qui changent l'état du lock, tous deux tracés.
- Le champ `hint` du refus `stale-requires-takeover` est la marche à suivre in-band que le plan 32-03 (guard `PreToolUse`) pourra nommer à un appelant refusé.
- `QUAL-01` reste potentiellement `Pending` dans `REQUIREMENTS.md` selon l'état des plans frères (32-03/32-05/32-06) — non vérifié dans ce mandat, à confirmer par le manager via `gsd_run query requirements.ready-ids`.

---
*Phase: 32-durcissement-du-driver-lock*
*Completed: 2026-08-17*
