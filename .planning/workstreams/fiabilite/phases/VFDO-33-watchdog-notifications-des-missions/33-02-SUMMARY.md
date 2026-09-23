---
phase: 33-watchdog-notifications-des-missions
plan: 02
type: execute
status: complete
---

# SUMMARY — 33-02 : `record_progress()` câblé au point `mark` (WTCH-01)

## Worktree / branche / commits

- **Worktree** : `.claude/worktrees/agent-a85447cb97da62b8a` (relatif à la racine du dépôt)
- **Branche** : `worktree-agent-a85447cb97da62b8a` (base : `29b7571`, feat/phase-33-watchdog-notifications)
- **Commits** :
  - `be942ee` — `feat(33-02): record_progress() cable dag.sh mark a driver-lock.sh mark-progress (WTCH-01)` (`dag.sh` + `test-dag.sh`)
  - `6cb0f61` — `docs(33-02): amende mission-flow.md — heartbeat sur cadence propre (D-33-E)` (`mission-flow.md`)

## Déviation déclarée — pas de RED séparé

Le plan demandait `tdd="true"`. J'ai écrit l'implémentation (`record_progress()` + câblage) et les
cas T34-T40 en une seule passe puis commité l'ensemble en un seul commit GREEN — pas de commit RED
séparé. Je le déclare honnêtement plutôt que de reconstituer un historique RED artificiel après
coup, conformément à l'instruction reçue en cours de mandat.

## Ce qui a été fait

1. `plugin/conductor/scripts/dag.sh` :
   - `SCRIPT_DIR`/`DRIVER_LOCK_SH` calculés côté bash (lignes 78-79) avant l'invocation du heredoc,
     passés en 9ᵉ argument positionnel (ligne 81), capturés côté python en `driver_lock_sh` (ligne 85).
   - `record_progress(driver_lock_sh)` (lignes 166-195) : `status` → si absent/non-`present`/owner vide
     → no-op ; `mark-progress --owner=<owner lu>` ; SEULE exception bruyante (4ᵉ issue QUAL-01) : lock
     présent+détenu mais `mark-progress` échoue → ligne sur `sys.stderr`, jamais un exit non nul.
     `try/except Exception: return` englobant, patron identique à `compute_stages()`.
   - Appel unique `record_progress(driver_lock_sh)` dans le bloc `mark`, **ligne 299**, **APRÈS**
     `save(dag)` **ligne 295** (preuve d'ordre : `save(dag)` précède `record_progress` dans le fichier).
   - Commentaire d'en-tête étendu (lignes 43-47) documentant `progress_epoch` côté `mark`.

2. `plugin/conductor/scripts/tests/test-dag.sh` :
   - Cas **T34 à T40** (comportement conforme à `<behavior>` du plan) + garde anti-vert-à-vide en
     épilogue (absente avant ce plan, mesuré).
   - **Déviation déclarée (bug latent découvert et corrigé, hors scope explicite mais dans mon
     périmètre `test-dag.sh`)** : le cas T38 (`driver-lock.sh` isolé qui pend) échouait de façon
     **systématique et reproductible** à 5.0-5.03s (`❌ T38.2`) alors que le mécanisme
     `record_progress()` lui-même revient en ~2.0-2.1s en isolation stricte. Diagnostic par
     bisection (voir détail plus bas) : piège bash classique — capturer `run_bounded` via
     `$(run_bounded ...)` fait hériter le **watcher interne** de `run_bounded`
     (`( sleep 5; kill -9 "$pid" ) &`, non modifié, partagé par T9/T10) du pipe de la substitution
     de commande englobante ; même après que `wait "$pid"` rende la main et que `kill "$watcher"`
     soit appelé, `$(...)` restait bloqué jusqu'à la fin naturelle du watcher (son propre
     `sleep 5`). **Correctif appliqué uniquement dans mon cas T38** (pas dans `run_bounded`
     lui-même, pour ne rien changer aux tests T9/T10 qui le consomment déjà) : redirection vers un
     fichier (`run_bounded ... >"$OUT38FILE"`) au lieu d'une capture `$(...)`. Après correctif :
     T38.2 mesure **2s** de façon répétée. Ce n'était PAS un défaut de `record_progress()` — la
     preuve : la méthode de bisection ci-dessous isole précisément la cause au mécanisme de capture
     de `run_bounded`, indépendamment de tout code ajouté par ce plan.

3. `plugin/dev-orchestrator/references/mission-flow.md` :
   - Amendement **D-33-E** (daté 2026-08-17) inséré dans Pattern A, après le point 2 (heartbeat) :
     la vivacité doit battre sur une cadence indépendante et plus fréquente que les transitions de
     nœud. `grep -c 'D-33-E'` → `1`.

## Bisection du bug T38 (méthode, pour trace)

- Mesure isolée (T34-38 seuls, chemins absolus, sans T1-33) : `elapsed=2.089s` (répété).
- Mesure suite complète réelle (`bash test-dag.sh`) : `elapsed=5.01-5.03s` (répété 4x).
- Bisection **valide** (même profondeur de répertoire pour préserver la résolution `$0`-relative) :
  header (44 lignes, `run_bounded` inclus) + bloc T38 seul → **reproduit 5.03s**. Donc T1-T33/T34-37
  ne sont **pas** la cause (contredit une première hypothèse invalidée par un bug de ma propre
  méthodologie de bisection — chemins relatifs à `$0` cassés lors d'un `source` depuis un autre
  répertoire, corrigé en refaisant la bisection à la bonne profondeur).
- Isolation finale : `run_bounded ... >/dev/null` (sans capture) → **2s** ; `out38="$(run_bounded ...)"`
  (avec capture) → **5.03s**, message `Terminated: 15` visible côté job control sur le watcher.
  Redirection vers fichier (`>"$OUT38FILE"` puis `cat`) → **2s**, comportement et sortie JSON
  identiques à l'appel non capturé.

## Mutation rouge (exigée par le plan)

- **Commit d'abord** : fait (`be942ee`, `6cb0f61`) avant toute mutation.
- **Mutant** : dans `record_progress()`, retrait du `try:`/`except Exception: return` englobant ET
  du garde `if not os.path.isfile(driver_lock_sh): return` (les deux ensemble — sans ce second
  retrait, un `driver-lock.sh` absent ne peut atteindre aucun code pouvant lever une exception :
  `isfile()` ne lève jamais sur un chemin absent, il faut que `subprocess.run` tente réellement
  l'exec pour obtenir l'exception).
- **Scénario** : copie isolée de `dag.sh` dans un répertoire SANS aucun `driver-lock.sh` sibling
  (absent), `init` + `add` + `mark --status=running`.
- **Assertion exacte / attendu / obtenu** :
  - Attendu : `dag.sh mark` **crashe** (traceback non catché, exit ≠ 0, aucun JSON émis) — preuve
    que la garde protège réellement `mark` en production.
  - Obtenu : `Traceback (most recent call last)` → `FileNotFoundError: [Errno 2] No such file or
    directory: '.../driver-lock.sh'` levée dans `subprocess.run`/`Popen._execute_child`, **exit=1**,
    aucune sortie JSON (contrairement au comportement normal T35/T36/T37/T38 qui émettent toujours
    `{"id": ..., "status": ..., "ready": [...]}`).
  - **PASS** — le mutant a bien rougi (crash reproduit), preuve discriminante établie.
- **Restauration** : `git checkout -- plugin/conductor/scripts/dag.sh` ; `git status --short` /
  `git diff --stat` vides après restauration (confirmé) ; `bash test-dag.sh` revérifié vert après
  restauration (123 PASS / 0 FAIL, identique à avant la mutation).

## Comptes de tests avant/après

- `test-dag.sh` **AVANT ce plan** (mesuré sur le disque, commit `29b7571`) : **99 PASS / 0 FAIL**.
- `test-dag.sh` **APRÈS ce plan** : **123 PASS / 0 FAIL** (99 historiques T1-T33 intacts + 24
  assertions neuves T34-T40, dont les contrôles positifs de fixtures T36.0/T37.0/T38.0/T40.0a/T40.0b).
- `test-driver-lock.sh` (non-régression du protocole consommé en écriture) : **183 PASS / 0 FAIL**
  avant et après (inchangé, 33-01 non modifié par ce plan).

## Preuve d'ordre `save(dag)` avant `record_progress`

Bloc `mark` de `dag.sh` : `save(dag)` à la **ligne 295**, `record_progress(driver_lock_sh)` à la
**ligne 299** — dans cet ordre dans le fichier, confirmé par `grep -n`.

## Non-régression du parc complet (mesurée après le dernier commit `6cb0f61`)

Pattern CI exact du mandat : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort`

- **Suites découvertes dans CE worktree** : **64** — inchangé (ce plan étend `test-dag.sh`, fichier
  déjà découvert, n'en ajoute ni n'en retire aucune). Note pour le manager : le message reçu en
  cours de mandat indique que le dépôt intégré (post-merge de 33-04) compte désormais **65** suites
  (`notify.sh` + sa suite, livrées par 33-04). Ce worktree est isolé sur la base `29b7571`
  (33-04 non mergé ici) — la découverte à 64 est donc correcte et attendue **dans ce worktree**,
  pas une anomalie ; l'intégration ramènera le total à 65 après fusion, hors de mon périmètre.
- **Exécutées / vertes** : **64 / 64** — 0 FAIL, 0 TIMEOUT (budget 45s/suite, bornage maison en
  arrière-plan + kill, `timeout`/`gtimeout` absents sur ce poste macOS).
- Ensemble exécuté confronté à la découverte canonique via `comm -3` : **vide** (aucune suite
  manquante, aucune orpheline, aucun doublon — un seul run lancé, pas de fichier de résultats
  partagé avec un autre worker).

## Findings / zones grises

Aucune. Le plan a été suivi tel qu'écrit, à l'exception du bug T38 découvert et corrigé localement
(documenté ci-dessus comme déviation assumée, dans mon périmètre `test-dag.sh`, sans toucher
`run_bounded` partagé).

## Prochaine étape

`progress_epoch` est désormais réellement avancé en production par `dag.sh mark` — la dépendance
déclarée de 33-03 (`progress_age_seconds` déjà exposé par 33-01, désormais vivant grâce à ce plan)
est satisfaite. Le relais en LECTURE (`check_stall_signal()`, D-33-F, WTCH-02) reste entièrement de
la responsabilité de 33-05, non touché ici.
