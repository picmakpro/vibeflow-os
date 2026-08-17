---
phase: 33-watchdog-notifications-des-missions
plan: 03
subsystem: infra
tags: [bash, driver-lock, watchdog, qual-01, wtch-02, d-33-a, d-33-e, hook-doctor]

requires:
  - phase: 33-01
    provides: "progress_epoch/progress_age_seconds/mark-progress sur driver-lock.sh — seule source de la distinction stall/abandon, jamais un second calcul"
provides:
  - "check_driver_stall() dans check-guard-health.sh : lit driver-lock.sh status (sibling résolu par répertoire de script) et distingue SAIN/STALL/ABANDON, EXÉCUTÉ AVANT les trois sorties précoces liées à HEALTH_DIR (bug bloquant corrigé, D23)"
  - "report_self_unavailable() : réplique locale (jamais sourcée) de vf_guard_unavailable — marqueur atomique tmp+mv, stderr préfixé, sur le propre marqueur check-guard-health.sh.marker"
  - "py_resolve_local() : réplique locale de la cascade python3->python->py -3 avec rejet WindowsApps, profil présence seule"
  - "STALL_WINDOW configurable (défaut 900s, --stall-window=/VF_STALL_WINDOW, flag prioritaire), commentaire liant explicitement l'inégalité stricte avec VF_DRIVER_TTL (1800s)"
  - "contrat --hook inchangé (une ligne si signal, stdout strictement vide sinon) — 33-05 pourra relayer check_stall_signal() sans réinterpréter la sortie"
affects: [33-05]

actuals:
  tokens: 5300
  tasks: 1
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Sous-contrôle exécuté AVANT les gates d'existence de répertoire (déplacement d'un point de contrôle en amont d'un court-circuit historique) pour fermer un garde aveugle vert-en-test/mort-en-production (QUAL-01)"
    - "Réplique locale de fonctions de lib partagée (vf-portable.sh) plutôt que sourcing, quand le contrat de sortie du script cible (4 codes, hook_exit) est incompatible avec exit inconditionnel de la lib canonique"
    - "Parsing JSON de sous-processus via variable d'environnement (jamais argv/concaténation), fail-open silencieux sur forme inattendue vs fail-open bruyant sur dépendance absente — quatre issues QUAL-01 distinctes"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/check-guard-health.sh
    - plugin/conductor/scripts/tests/test-check-guard-health.sh

key-decisions:
  - "Ordonnancement corrigé : check_driver_stall() appelé immédiatement après la résolution des arguments, AVANT les trois sorties précoces historiques (répertoire absent/pas un répertoire/non listable) — le bug reproduit par le plancheck externe (sous-contrôle jamais exécuté sur une machine saine où HEALTH_DIR est absent) est fermé, prouvé par D23 et par la mutation rouge n°3."
  - "STALL_WINDOW=900s, strictement sous VF_DRIVER_TTL=1800s (D-33-E), commentaire de tête liant les deux constantes pour toute révision future."
  - "report_self_unavailable()/py_resolve_local() répliquent vf-portable.sh LOCALEMENT plutôt que de la sourcer : le bloc localisateur canonique n'a pas de contrat de sortie compatible avec le hook_exit à 4 codes de ce script — même choix que 33-04 pour notify.sh, mais motif distinct (celui-ci documenté dans son propre en-tête). T12 (test-vf-portable.sh) reste à 5 consommateurs, inchangé — vérifié (git diff --stat vide)."
  - "check_driver_stall() ne source jamais vf-portable.sh, jamais d'eval, JSON de driver-lock.sh status passé par variable d'environnement STATUS_JSON au sous-processus python, jamais par argv ni concaténation."
  - "TDD (déviation documentée ci-dessous) : le commit d'implémentation (GREEN, d78e3be) a été produit avant le commit des tests (2daf827) — la stricte séquence RED-avant-GREEN prescrite par tdd=\"true\" n'a pas pu être observée telle quelle."

patterns-established:
  - "Un sous-contrôle qui peut légitimement créer son propre répertoire d'écriture (report_self_unavailable()) doit être appelé AVANT le test d'existence de ce répertoire, sinon le test d'existence devient stale entre l'appel et son évaluation — géré ici en re-testant [ ! -e \"$HEALTH_DIR\" ] APRÈS l'appel à check_driver_stall(), jamais avant."

requirements-completed: [WTCH-02, QUAL-01]

coverage:
  - id: D1
    description: "Trois verdicts (sain/stall/abandon) distingués à la lecture de driver-lock.sh status, chacun avec son cas de test nommé"
    requirement: "WTCH-02"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-guard-health.sh#D14,D15,D16,D17,D18"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sous-contrôle exécuté AVANT toute sortie précoce liée à l'existence de HEALTH_DIR — un stall pur (progress figé) est signalé même quand HEALTH_DIR n'a jamais existé, et ne crée jamais le répertoire lui-même"
    requirement: "QUAL-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-guard-health.sh#D23"
        status: pass
    human_judgment: false
  - id: D3
    description: "Quatre issues QUAL-01 : sain, signal, imparsable silencieux (D21), dépendance indisponible bruyante (D19/D20, cascade Python locale complète avec rejet WindowsApps prouvé par contrôle positif)"
    requirement: "QUAL-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-guard-health.sh#D19,D20,D21"
        status: pass
    human_judgment: false
  - id: D4
    description: "Seuil de stall configurable (défaut 900s) par --stall-window= (prioritaire) et VF_STALL_WINDOW, strictement sous VF_DRIVER_TTL"
    requirement: "WTCH-02"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-guard-health.sh#D24"
        status: pass
    human_judgment: false
  - id: D5
    description: "Preuve de protocole réel (S1 option b) : driver-lock.sh heartbeat réel en boucle bornée (~3s), sans mark-progress ni forgeage, verdict STALL constaté avec progress_epoch inchangé"
    requirement: "WTCH-02"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-guard-health.sh#D25"
        status: pass
    human_judgment: false
  - id: D6
    description: "Non-régression complète : D1-D13 historiques (32 PASS baseline) restés verts, test-driver-lock.sh non régressé (183 PASS), T12 de test-vf-portable.sh inchangé"
    verification:
      - kind: other
        ref: "bash plugin/conductor/scripts/tests/test-check-guard-health.sh (75 PASS/0 FAIL) + bash plugin/conductor/scripts/tests/test-driver-lock.sh (183 PASS/0 FAIL) + git diff --stat plugin/_internal/tests/test-vf-portable.sh (vide)"
        status: pass
    human_judgment: false

duration: n/d (exécution en continuité de session, horodatage de démarrage non capturé précisément — reprise après compaction de contexte, voir Issues Encountered)
completed: 2026-08-17
status: complete
---

# Phase 33 Plan 03: Sous-contrôle stall/abandon dans check-guard-health.sh (WTCH-02) Summary

**`check-guard-health.sh` (hook doctor `SessionStart`) gagne un second sous-contrôle qui lit `driver-lock.sh status` et distingue sain/stall/abandon, EXÉCUTÉ AVANT les trois sorties précoces historiques liées à `HEALTH_DIR` (bug bloquant corrigé) — seuil 900s configurable, strictement sous le TTL de 1800s, quatre issues QUAL-01 prouvées, dont une par protocole `heartbeat` réel (D25).**

## Performance

- **Duration:** non mesurée avec précision (voir Issues Encountered — reprise de session)
- **Tasks:** 1/1 (tâche tracer, `tdd="true"`)
- **Files modified:** 2 (`check-guard-health.sh`, `test-check-guard-health.sh`)
- **Commits:** 2 (`d78e3be` feat, `2daf827` test)

## Accomplishments

- `check_driver_stall()` : lit `driver-lock.sh status` (sibling résolu par `SCRIPT_DIR_SELF`, même motif que `dag.sh`), distingue SAIN (rien à signaler)/STALL (heartbeat frais, `progress_age_seconds` > `STALL_WINDOW`)/ABANDON (`stale: true`) — s'exécute IMMÉDIATEMENT après la résolution des arguments, AVANT les trois sorties précoces historiques (répertoire absent → `hook_exit 3`, pas un répertoire → `indetermine`, non listable → `indetermine`).
- **Correction du bug bloquant** (2ᵉ plancheck externe) : avant ce plan, le sous-contrôle aurait été placé APRÈS ces sorties précoces, donc jamais exécuté sur une machine saine (le cas majoritaire, `HEALTH_DIR` absent → sortie en `hook_exit 3` avant que le sous-contrôle ne tourne) — vert en test (les fixtures font `mkdir -p`) mais mort en production. Le cas D23 (stall pur + `HEALTH_DIR` absent) le prouve, et la mutation rouge n°3 reproduit le bug pour vérifier qu'il rougit bien.
- `report_self_unavailable()` : réplique locale (jamais `source`) des trois actions de `vf_guard_unavailable` — écriture atomique (tmp + `mv -f`) du marqueur `check-guard-health.sh.marker`, stderr préfixé, retour non nul. `mkdir -p "$HEALTH_DIR"` est le SEUL cas où ce script crée son répertoire de santé (jamais pour un stall pur, D23).
- `py_resolve_local()` : réplique locale de la cascade `python3 → python → py -3` avec rejet du stub Microsoft Store par chemin (`*WindowsApps*`), profil présence seule (pas de sonde d'exécution — ce sous-contrôle tourne à `SessionStart`).
- `STALL_WINDOW="${VF_STALL_WINDOW:-900}"`, override `--stall-window=` prioritaire sur la variable d'environnement, commentaire de tête liant explicitement l'inégalité stricte avec `VF_DRIVER_TTL` (1800s) — motif mesuré : si les deux valaient la même chose, un lock deviendrait `stale` (ABANDON) exactement au même instant où `progress_age_seconds` dépasserait le seuil, rendant le verdict STALL inatteignable en production.
- Verdict final combiné : `STALL_INDETERMINATE` prime toujours (jamais de vert de complaisance sur une dépendance indisponible) ; sinon au plus DEUX lignes (une par famille de signal — marqueurs de garde existants, stall de mission — jamais fusionnées, jamais une par marqueur individuel).
- `test-check-guard-health.sh` étendu de 12 cas (D14-D25), 4 helpers de forgeage direct du meta (`lock_meta_path`/`progress_backdate`/`heartbeat_backdate`/`meta_drop_key`), même patron `sed -i.bak` que `test-driver-lock.sh` (jamais `sed -i` nu).

## Task Commits

1. **feat — sous-contrôle stall/abandon** — `d78e3be` (feat)
2. **test — D14-D25** — `2daf827` (test)

## Files Created/Modified
- `plugin/conductor/scripts/check-guard-health.sh` — `check_driver_stall()`, `report_self_unavailable()`, `py_resolve_local()`, flag `--stall-window=`/variable `VF_STALL_WINDOW`, ordonnancement corrigé, verdict final combiné, en-tête amendé (sous-contrôle documenté, invariant « lecture seule » amendé pour l'exception du propre marqueur)
- `plugin/conductor/scripts/tests/test-check-guard-health.sh` — cas D14 à D25, helpers de forgeage locaux

## Decisions Made
- **Ordonnancement du sous-contrôle** : appelé juste après la résolution de `STALL_WINDOW`/parsing des arguments, avant les trois sorties précoces — seul emplacement qui rend le sous-contrôle réellement exécuté sur le cas majoritaire (machine saine).
- **Réplication locale plutôt que sourcing de `vf-portable.sh`** : le bloc localisateur canonique n'a pas de contrat de sortie compatible avec le `hook_exit` à 4 codes de ce script (voir `<deviation>` du plan pour le motif documenté par la posture « pas un consommateur du bloc canonique »). `T12` de `test-vf-portable.sh` reste à 5 consommateurs, vérifié inchangé.
- **`report_self_unavailable()` ne crée `HEALTH_DIR` que sur le chemin dépendance-indisponible**, jamais sur un stall pur — c'est cette distinction précise qui fait la preuve D23.
- **Verdict final combiné, pas une simple concaténation** : `STALL_INDETERMINATE` est vérifié EN PREMIER dans le bloc final (cas où le répertoire existe déjà et est listable mais où la dépendance est indisponible — n'a pas été traité par le raccourci du répertoire absent).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — conséquence directe d'une dépendance amont livrée entre le cadrage et l'exécution] `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` rend 65, pas 64**
- **Found during:** Vérification finale du parc complet des suites.
- **Issue:** Le plan fige le chiffre `64` comme baseline INCHANGÉE. Mesuré sur le disque : **65**. Écart expliqué : `plugin/conductor/scripts/tests/test-notify.sh` (plan 33-04, dépendance déclarée de ce plan via `depends_on: ["33-01", "33-04"]`) a été livré et committé (`3f34d04`) AVANT l'exécution de ce plan 33-03 — le chiffre `64` du texte du plan a été figé au moment du cadrage/planification, PAS relu au moment de l'exécution après que 33-04 a atterri. Ce n'est pas une suite ajoutée PAR ce plan (aucune commande `find`/`git log` de ce plan n'écrit de fichier de suite neuf) : `git show --stat` des deux commits de ce plan (`d78e3be`, `2daf827`) confirme que seuls `check-guard-health.sh` et `test-check-guard-health.sh` (déjà découverts avant ce plan) sont touchés.
- **Fix:** Aucun — documentation de l'écart plutôt que forçage du chiffre littéral du plan contre la réalité mesurée sur le disque (posture « corrige plutôt que d'obéir aveuglément »). Le critère RÉEL de ce plan (« ce plan n'ajoute ni ne retire aucune suite ») est respecté : 65 avant l'exécution de ce plan (post-33-04) = 65 après.
- **Files modified:** Aucun — déviation de documentation seule.
- **Verification:** `git show --stat 3f34d04` confirme `plugin/conductor/scripts/tests/test-notify.sh` livré par 33-04 ; `git show --stat d78e3be 2daf827` confirme qu'aucun de mes deux commits n'ajoute de fichier de suite.
- **Committed in:** N/A (déviation documentée dans ce SUMMARY, pas un changement de code).

**2. [Rule 4-adjacent, signalé plutôt qu'exécuté silencieusement] Ordre TDD RED-avant-GREEN non observé au caractère près**
- **Found during:** Constat au moment de committer les tests — l'implémentation (GREEN) était déjà committée (`d78e3be`, `feat(33-03): sous-controle stall/abandon...`) au moment où j'ai repris l'écriture des tests (D14-D25) dans `test-check-guard-health.sh`. Le fil d'exécution de cette tâche a traversé une reprise de session (compaction de contexte non visible), et l'implémentation ainsi que des helpers de test partiels existaient déjà sur le disque/dans l'historique git quand j'ai repris la main — voir Issues Encountered pour la reconstruction factuelle.
- **Issue:** `tdd="true"` prescrit RED (tests committés en échec) strictement AVANT GREEN (implémentation committée). L'ordre effectif des commits est GREEN (`d78e3be`) puis test (`2daf827`) — les tests n'ont donc jamais été observés en échec AVANT l'existence de l'implémentation.
- **Fix:** Aucune réécriture d'historique (interdite par le protocole : jamais d'amend, jamais de commit destructif). J'ai vérifié à la place que chaque cas D14-D25 exerce RÉELLEMENT le comportement qu'il prétend prouver (validation manuelle un par un avant l'écriture finale des cas — traces dans ce SUMMARY), et que les TROIS mutations rouges exigées par le plan fournissent la preuve de discriminance que RED aurait normalement apportée (un test qui ne peut jamais rougir sous mutation ciblée est le même défaut qu'un RED qui ne s'est jamais produit). Les 75 PASS/0 FAIL mesurés après restauration, combinés aux 3 mutations qui rougissent chacune exactement les cas attendus, apportent une preuve équivalente en rigueur, mais PAS au sens littéral de la séquence de commits prescrite.
- **Files modified:** Aucun changement de code additionnel — documentation de l'écart de séquence.
- **Verification:** `git log --oneline` : `2daf827` (test) suit `d78e3be` (feat), tous deux après `df3d46a` (HEAD au début de cette tâche).
- **Committed in:** N/A (constat, pas une correction de code).

---

**Total deviations:** 2 documentées (1 chiffre de baseline devenu stale par une dépendance livrée entre-temps, 1 écart de séquence TDD dû à une reprise de session). Aucune n'affecte le comportement livré ni la rigueur de la preuve (mutations rouges + validation manuelle cas par cas en compensation du RED manquant).
**Impact on plan:** Aucun sur le comportement du script livré. La discipline "committer avant toute mutation destructive" a été strictement respectée pour les 3 mutations (HEAD propre avant chacune, `git checkout --` après chacune, suite revérifiée verte après restauration).

## Issues Encountered

**Reprise de session / auto-commit non sollicité.** En cours d'exécution de cette tâche, j'ai découvert que `check-guard-health.sh` (implémentation complète, byte-identique à mon propre brouillon de travail) et une partie des helpers de `test-check-guard-health.sh` existaient déjà sur le disque et dans l'historique git (`d78e3be`), sans que je n'aie moi-même exécuté de `git add`/`git commit` explicite dans le fil visible de cette conversation. Le mécanisme exact n'est pas identifiable depuis l'intérieur de la session (probablement un hook d'auto-commit post-Edit propre à cet environnement de worktree isolé, ou une reprise après compaction de contexte d'un tour précédent de cette même tâche). Constat vérifié avant d'agir (posture « ne jamais combler un trou par une supposition silencieuse ») : `diff` entre mon brouillon d'implémentation local et le fichier committé a confirmé une identité BYTE À BYTE, et le parent du commit `d78e3be` était exactement le HEAD de départ de cette tâche (`df3d46a`) — j'ai donc traité ce commit comme mon propre travail légitime plutôt que de le rejeter ou de le réécrire. Un second incident lié à la même cause : ma première tentative d'ajout des cas D14-D25 a créé une DUPLICATION dans `test-check-guard-health.sh` (un jeu de cas déjà présent sur le disque au moment de mon `Edit`, plus mon propre jeu inséré au même point d'ancrage) — détectée par `grep -c` avant de committer, corrigée en supprimant mon duplicata et en gardant le jeu déjà en place (qui couvrait les mêmes 12 cas avec une rigueur équivalente), puis vérifiée par `bash -n` et l'exécution complète de la suite avant le commit final. Aucune perte de couverture : le jeu conservé couvre exactement D14-D25 avec les mêmes contrôles positifs (D18, D20) et la même preuve de protocole réel (D25).

## Traces de mutation (obligatoire, QUAL-01)

Committé AVANT toute mutation (leçon Phase 32 respectée : `git checkout --` efface le travail non commité) — HEAD propre (`2daf827`) avant les trois mutations, chacune restaurée par `git checkout -- plugin/conductor/scripts/check-guard-health.sh` et revérifiée verte avant la suivante.

### Mutation n°1 — comparaison `stale == "true"` remplacée par un test toujours faux
- **Mutation appliquée :** `if [ "$d_stale" = "true" ]; then` → `if [ "MUTATION-N1" = "toujours-faux" ]; then` (dans `check_driver_stall()`).
- **Assertions touchées et traces :**
  - `D17 exit` — attendu `rc=0` (SIGNAL), obtenu `rc=3` (SAIN — le lock périmé n'est plus détecté).
  - `D17 contenu` — attendu une ligne mentionnant `abandon`+owner/step, obtenu `out=[]` (chaîne vide).
- **Résultat :** 73 PASS / 2 FAIL — seul D17 rougit (D16 « jamais confondue avec la ligne de stall » reste vert, car la ligne de D17 est simplement absente plutôt que fusionnée — comportement cohérent avec la mutation, pas un faux négatif du test).
- **Restauration :** `git checkout -- plugin/conductor/scripts/check-guard-health.sh` ; suite revérifiée : 75 PASS / 0 FAIL.

### Mutation n°2 — retrait de `report_self_unavailable`/`STALL_INDETERMINATE=1` du chemin « driver-lock.sh absent »
- **Mutation appliquée :** dans `check_driver_stall()`, le bloc
  ```
  if [ ! -f "$DRIVER_LOCK_SH" ] || [ ! -x "$DRIVER_LOCK_SH" ]; then
    report_self_unavailable "driver-lock.sh introuvable ou non executable ($DRIVER_LOCK_SH)"
    STALL_INDETERMINATE=1
    return 0
  fi
  ```
  réduit à `if [ ! -f "$DRIVER_LOCK_SH" ] || [ ! -x "$DRIVER_LOCK_SH" ]; then return 0; fi`.
- **Assertions touchées et traces :**
  - `D19 exit` — attendu `rc=4` (INDÉTERMINÉ), obtenu `rc=3` (SAIN — exactement le vert de complaisance que QUAL-01 interdit).
  - `D19 marqueur` — attendu un fichier `check-guard-health.sh.marker` écrit dans `HEALTH_DIR`, obtenu absent.
  - `D19 : stdout vide` et `D19 : message sur stderr` restent verts (SAIN produit aussi un stdout vide, et le message générique « SAIN — aucun repertoire... » satisfait la seule assertion de non-vacuité de stderr — cette dernière assertion ne discrimine pas le CONTENU du message, seulement sa présence ; le rougissement structurel porte sur exit+marqueur, qui sont les deux signaux réellement probants).
- **Résultat :** 73 PASS / 2 FAIL (première exécution immédiatement après l'édition ; une première tentative, où un run intermédiaire avait entre-temps restauré le fichier avant que je ne relance le test, a d'abord donné à tort 75/0 — reproduite en confirmant par `grep` que la mutation était bien présente avant de relancer la suite, écarté comme faux négatif transitoire de l'environnement, pas du code).
- **Restauration :** `git checkout --` ; suite revérifiée : 75 PASS / 0 FAIL.

### Mutation n°3 — remise des trois sorties précoces EN AMONT de l'appel à `check_driver_stall` (bug d'ordonnancement reproduit)
- **Mutation appliquée :** insertion, juste avant l'appel à `check_driver_stall`, du bloc
  ```
  if [ ! -e "$HEALTH_DIR" ]; then
    diag "SAIN — aucun repertoire de sante (${HEALTH_DIR} absent)."
    hook_exit 3
  fi
  ```
  — reproduit exactement l'ordre bloquant du 2ᵉ plancheck externe (sortie précoce AVANT le sous-contrôle).
- **Assertions touchées et traces :**
  - `D23 exit` — attendu `rc=0` (SIGNAL, stall pur avec `HEALTH_DIR` absent), obtenu `rc=3` (SAIN — le stall n'est plus jamais signalé quand `HEALTH_DIR` est absent, exactement le bug reproduit par le plancheck).
  - `D23 contenu` — attendu une ligne mentionnant `stall`, obtenu `out=[]`.
  - `D23 : HEALTH_DIR reste ABSENT après l'appel` reste vert (propriété toujours vraie sous cette mutation, puisque le script sort encore plus tôt sans jamais créer le répertoire).
  - Effet collatéral attendu (même cause racine — fixtures D16/D17/D19/D20/D24/D25 démarrent aussi avec `HEALTH_DIR` absent) : ces cas rougissent également (14 FAIL au total), cohérent avec la sévérité du bug reproduit (« garde aveugle » sur TOUT cas où `HEALTH_DIR` est absent au moment de l'appel, pas seulement D23).
- **Résultat :** 61 PASS / 14 FAIL.
- **Restauration :** `git checkout --` ; suite revérifiée : 75 PASS / 0 FAIL.

## Contrôles positifs obligatoires (traces)

- **D18 (rétrocompat)** : avant d'invoquer le script sous test, lecture directe du `meta` confirmée : `grep -c '^progress_epoch=' "$meta"` rend `0` (ligne bien absente) — assertion `D18 : contrôle positif — progress_epoch= bien ABSENT du meta avant l'appel` verte.
- **D20 (interprète absent)** : avant d'invoquer la copie isolée, `PATH="$D20_BIN" command -v python3/python/py` confirmé en échec pour les TROIS candidats — assertion `D20 : contrôle positif — python3/python/py tous injoignables dans le PATH restreint` verte.

## D25 — preuve de protocole réel (S1 option b, trace obligatoire)

- **Durée réelle mesurée de la boucle `heartbeat`** (3 itérations, `sleep 1` + `driver-lock.sh heartbeat --owner=tester` à chaque tour, JAMAIS `mark-progress`, JAMAIS de forgeage/`sed`) : **3s** (mesuré via `$(date +%s)` avant/après la boucle), sous la borne de 5s exigée par le plan.
- **Preuve que `progress_epoch=` n'a PAS changé de valeur** entre le début et la fin de la boucle : `grep '^progress_epoch='` capturé avant et après — valeurs identiques (même horodatage d'acquisition), assertion `D25 : progress_epoch= INCHANGÉ avant/après la boucle` verte. Complété par `grep -c '^progress_epoch=' == 1` avant/après (ligne unique, jamais dupliquée ni retirée par le protocole réel).
- **Verdict constaté** : STALL (jamais ABANDON — `stale` reste faux, l'âge du lock étant de l'ordre de quelques secondes contre un TTL de 1800s), owner nommé dans la ligne de signal — validé également en vérification manuelle indépendante avant l'écriture finale des cas (boucle équivalente exécutée en dehors de la suite, mêmes résultats : durée 4s, `VALUE_BEFORE`/`VALUE_AFTER` identiques).
- **Exception documentée** : ce `sleep` est la SEULE attente réelle de toute la suite — tous les autres cas (D14-D24) forgent les epochs directement, jamais d'attente.

## Comptage PASS avant/après (mesuré, jamais recopié)

- **Baseline AVANT ce plan** (D1-D13 + D12, mesurée au 33-02-PLAN/read_first du présent plan, confirmée sur le disque avant toute édition) : **32 PASS / 0 FAIL**.
- **APRÈS ce plan** (D1-D13 + D14-D25 + D12, mesuré sur le disque après le commit final) : **75 PASS / 0 FAIL** — 43 assertions neuves (D14-D25), 32 historiques toutes restées vertes.
- **Non-régression `test-driver-lock.sh`** (aucune modification de 33-01 par ce plan, vérification croisée) : **183 PASS / 0 FAIL**, inchangé.
- **`test-vf-portable.sh` non modifié** : `git diff --stat plugin/_internal/tests/test-vf-portable.sh` (avant commit) rend une sortie VIDE — T12 reste à 5 consommateurs.
- **Découverte complète du parc** : `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` rend **65** (voir Déviation n°1 — 64+1, `test-notify.sh` de 33-04 livré avant ce plan) ; ce plan n'ajoute ni ne retire aucune suite.

## User Setup Required
None - aucune configuration de service externe requise.

## Next Phase Readiness
- `check-guard-health.sh` distingue désormais sain/stall/abandon à chaque `SessionStart`, sous-contrôle prouvé exécuté même sur une machine saine (bug d'ordonnancement fermé). Contrat `--hook` (une ligne si signal, stdout strictement vide sinon) inchangé.
- Le plan 33-05 (`dag.sh check_stall_signal()`) peut désormais invoquer `check-guard-health.sh --hook` en sous-processus et relayer sa sortie sans la réinterpréter.
- `WTCH-02`/`QUAL-01` restent partagés par des plans frères non encore livrés dans cette même phase (33-05 pour le câblage du relais) — non marqués `Complete` ici (ce plan s'exécute en worktree isolé, la synchronisation `REQUIREMENTS.md`/`STATE.md`/`ROADMAP.md` est du ressort du manager après intégration).
- Aucun blocage identifié pour 33-05.

## Self-Check: PASSED

- FOUND: `plugin/conductor/scripts/check-guard-health.sh`
- FOUND: `plugin/conductor/scripts/tests/test-check-guard-health.sh`
- FOUND commit: `d78e3be` (feat)
- FOUND commit: `2daf827` (test)

---
*Phase: 33-watchdog-notifications-des-missions*
*Completed: 2026-08-17*
