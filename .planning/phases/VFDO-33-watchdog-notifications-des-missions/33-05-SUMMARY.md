---
phase: 33-watchdog-notifications-des-missions
plan: 05
type: execute
status: complete
requirements: [WTCH-02, WTCH-03, WTCH-04]
---

# SUMMARY — 33-05 : `check_stall_signal()` + `record_milestone()` câblés au point `mark` (WTCH-02/WTCH-03), clôture Windows (D-33-C)

## Worktree / branche / commits

- **Worktree** : `/Users/samuel/Documents/dev/vibeflow-os/.claude/worktrees/agent-a2a0fb99a3365a95f`
- **Branche** : `worktree-agent-a2a0fb99a3365a95f` (base : `ce4454f`, `feat/phase-33-watchdog-notifications`)
- **Commits** :
  - `80c4e22` — `feat(33-05): check_stall_signal() + record_milestone() cablés à dag.sh mark (WTCH-02/WTCH-03)` (`dag.sh` + `notify.sh` mode)
  - `47ad0b7` — `test(33-05): T41-T47 pour check_stall_signal()/record_milestone() (WTCH-02/WTCH-03)` (`test-dag.sh`)
  - `f1b93ea` — `docs(33-05): recette de clôture Windows, rattachée au fil testeurs issue #20 (D-33-C)` (`33-CLOTURE-WINDOWS.md`)

## Décision argumentée — mode d'exécution de `notify.sh` (défaut d'intégration signalé par le mandat)

**Mesuré avant toute décision** (dépôt tel que livré par 33-04) :
```
./plugin/conductor/scripts/notify.sh "T" "C"   → permission denied, exit=126
bash plugin/conductor/scripts/notify.sh "T" "C" → exit=0
```
Confirmé : `notify.sh` était committé en mode `644`. Le plan 33-05 prescrit littéralement
`subprocess.run([notify_sh, title, body], ...)` — un exec direct — et son acceptance criteria
attend le grep `[notify_sh, title, body]` (forme liste, exec direct). Avec `notify.sh` en `644`,
cet appel lève `PermissionError`, absorbée par le `try/except Exception: return` englobant de
`record_milestone()` — **fail-open silencieux** : la notification ne serait JAMAIS partie en
production, sans qu'aucun signal ne le montre. C'est exactement le mode de défaillance que cette
phase combat.

**Tranché : option (a) — rendre `notify.sh` exécutable dans le dépôt**
(`git update-index --chmod=+x plugin/conductor/scripts/notify.sh` + `chmod +x` sur le fichier de
travail). Raisons :
- Cohérent avec les 18 autres scripts de `plugin/conductor/scripts/` déjà en `755`, et avec
  `check-guard-health.sh` invoqué par ce même plan via le même patron d'exec direct
  (`[check_guard_health_sh, "--hook"]`) — `check-guard-health.sh` reste en `644` dans ce dépôt,
  mais c'est un cas différent : sa dégradation silencieuse est le comportement NOMINAL testé et
  documenté par le plan lui-même (T41 sous-cas 2, « absent/non exécutable »), alors que pour
  `notify.sh`, une notification qui ne part jamais est précisément le défaut visé par WTCH-03 —
  pas un cas de dégradation acceptable.
- Ne casse aucun critère du plan : la forme d'appel `[notify_sh, title, body]` prescrite reste
  intacte (aucun changement de code, seulement un bit de permission), contrairement à l'option
  (b) (invoquer via l'interpréteur `["bash", notify_sh, ...]`) qui aurait exigé de réécrire le
  site d'appel et de contredire le grep littéral `[notify_sh, title, body]` attendu par
  l'acceptance criteria du plan — sans qu'il s'agisse d'un véritable écart d'interface de
  `notify.sh` (son interface CLI, elle, est restée `<TITLE> <BODY>`, confirmée sur disque avant
  d'écrire le code, cf. section suivante).
- Déviation déclarée : `notify.sh` sort du `files_modified` strict de ce plan
  (`dag.sh`, `test-dag.sh`, `33-CLOTURE-WINDOWS.md`) — le `git diff --name-only` porte donc un
  fichier de plus que la liste déclarée. Documenté ici plutôt qu'absorbé en silence, cohérent
  avec le sur-ensemble strict explicitement toléré par l'acceptance criteria « portée-plan
  exacte » du plan (« ou son sur-ensemble strict si un écart d'interface documenté au SUMMARY a
  forcé un fichier de plus »).

**Preuve que l'appel aboutit réellement, après correctif** :
```
plugin/conductor/scripts/notify.sh "T" "C" ; echo $?
→ 0   (126 avant le correctif)
```
Vérifié aussi de bout en bout via les cas T42/T43 (copie réelle de `notify.sh`, invoquée en exec
direct par une copie isolée de `dag.sh` via `subprocess.run([notify_sh, title, body], ...)`) :
les deux passent au vert avec la copie en mode exécutable — preuve intégrée à la suite, pas
seulement une vérification manuelle ponctuelle.

## Interface réelle de `notify.sh` — assomption du spike CONFIRMÉE

Relue sur disque avant d'écrire le code (`plugin/conductor/scripts/notify.sh`, tâche 1
`read_first`) : `Usage : notify.sh <TITLE> <BODY>`, deux positionnels, `exit 0` inconditionnel
(y compris si arguments manquants/vides). Strictement conforme à l'assomption
`[notify_sh, title, body]` documentée par `33-SPIKE-canal-notification.md` et confirmée par le
2ᵉ plancheck externe (`33-PLANCHECK-EXTERNE.md`). Aucun écart d'interface constaté — le code
écrit reprend la forme exacte prescrite par le plan, sans adaptation.

## Ce qui a été fait

### Tâche 1 — `dag.sh` + `test-dag.sh`

1. `plugin/conductor/scripts/dag.sh` :
   - `CHECK_GUARD_HEALTH_SH`/`NOTIFY_SH` ajoutés à côté de `SCRIPT_DIR`/`DRIVER_LOCK_SH` (même
     résolution par répertoire de script, jamais par cwd). Passés en 10ᵉ/11ᵉ arguments
     positionnels au heredoc python (`driver_lock_sh` restait en position 9, posé par 33-02 —
     relu sur disque avant d'ajouter, confirmé inchangé).
   - `check_stall_signal(check_guard_health_sh)` (D-33-F) : relais fidèle sur `stderr` de
     `check-guard-health.sh --hook`, **aucun filtre de statut**, `timeout=2`,
     `try/except Exception: return` englobant unique — même patron de dégradation que
     `record_progress()`.
   - `record_milestone(notify_sh, nid, status, mission_file)` (WTCH-03) : filtre `status in
     ("done", "failed")` en tête de fonction, `title`/`body` construits à partir de `nid`,
     `status`, `os.path.basename(mission_file)`, appel `subprocess.run([notify_sh, title, body],
     stdout=DEVNULL, stderr=DEVNULL, timeout=2, check=False)`, même garde `try/except` englobante.
   - Bloc `mark` : ordre strict vérifié par grep -n — `save(dag)` (ligne 352) < appel
     `check_stall_signal(` (ligne 358) < appel `record_milestone(` (ligne 360). `record_progress()`
     (33-02) reste avant les deux nouveaux appels.
   - Commentaire d'en-tête étendu pour documenter WTCH-02/WTCH-03 côté `mark`.

2. `plugin/conductor/scripts/tests/test-dag.sh` :
   - Ajout de l'helper `assert_eq` (égalité stricte) — absent du fichier jusqu'ici, nécessaire
     aux assertions de valeur exacte (chaîne vide, nombre de champs). Découvert en cours
     d'exécution (première passe : `assert_eq: command not found` sur 6 sites) — corrigé avant
     de considérer la suite verte.
   - **T41** (relais `check_stall_signal()`, D-33-F) : sous-cas 1 (fixture `--hook` fonctionnelle,
     `status=done`) → ligne stall EXACTE relayée sur stderr ; sous-cas 2 (sibling absent) →
     dégradation silencieuse, aucune ligne ; sous-cas 3 (`status=running`, même fixture que le
     sous-cas 1) → la ligne stall apparaît quand même, preuve de l'absence de filtre de statut.
     Contrôle positif T41.0 sur la fixture avant tout appel à `dag.sh`.
   - **T42/T43** (`record_milestone()` sur `done`/`failed`) : copie du VRAI `notify.sh` (posé par
     33-04), instrumentée d'une ligne de journalisation synchrone (TITLE/BODY) insérée
     juste après la validation d'arguments et avant le dispatch de canal — modification de la
     COPIE uniquement, jamais du fichier de production. `VF_NOTIFY_FORCE_CHANNEL=linux` +
     `PATH` restreint à un jeu de binaires curés (`uname dirname grep cat bash python3 env sleep
     touch`, aucun `osascript`/`notify-send`/`terminal-notifier`/`powershell.exe` réel) — même
     patron que `test-notify.sh` (33-04). Contrôles positifs T42.0/T43.0 sur la copie
     instrumentée avant tout appel à `dag.sh`.
   - **T44** (discriminance, marquée « NE JAMAIS RETIRER ») : `status=running` → journal absent
     après le `mark`, preuve que `notify.sh` n'est jamais invoqué sur ce statut. Contrôle positif
     T44.0 (la fixture journalise bien quand invoquée seule) avant l'assertion négative.
   - **T45** : `notify.sh` absent → `mark --status=done` reste vert, DAG mis à jour normalement.
   - **T46** (patron T38) : `notify.sh` isolé qui `sleep 30` → retour en moins de 5 s
     (`run_bounded`, watcher à 5 s ; `timeout=2` interne), DAG déjà persisté `status=failed` sur
     disque avant le retour de l'appel pendant. Contrôle positif T46.0 sur le processus pendant.
     Redirection vers fichier (jamais `$(run_bounded ...)` directement) — même piège documenté
     par 33-02 dans son SUMMARY, relu avant d'écrire ce cas.
   - **T47** : non-régression statique — `shell=True` toujours à 0, appels `notify.sh`/
     `check-guard-health.sh` en liste, `hooks.json`/`check-capability-activation.sh` absents de
     `dag.sh`.

### Tâche 2 — `33-CLOTURE-WINDOWS.md`

Document créé, rattaché explicitement au fil testeurs Windows de l'issue #20, portant la mention
« condition de clôture, pas un gate dur », reprenant les trois zones NON PROUVÉES du spike
(chaîne Windows jamais exécutée, AUMID arbitraire vs AUMID PowerShell non tranché, latence non
mesurée) sans en ajouter une quatrième non sourcée. Aucune tentative d'exécution réelle — la
recette est écrite comme un protocole en attente d'un testeur humain sur Win10/11.

## Mutations rouges (traces exactes)

### Mutation n°1 — `record_milestone()`

Retiré temporairement le `try/except Exception: return` englobant de `record_milestone()`
(remplacement du bloc, `git checkout -- dag.sh` en restauration). Fixture : `notify.sh` isolé
`chmod 000` dans un répertoire de test hors dépôt. Appel : copie isolée de `dag.sh` (mode exec
posé), `mark --file=... --id=n1 --status=done`.

- **Assertion attendue** (comportement gardé, baseline) : exit 0, DAG mis à jour, aucun crash.
- **Obtenu (mutant)** : `Traceback (most recent call last)` → `record_milestone` → `subprocess.run`
  → `PermissionError: [Errno 13] Permission denied: '.../notify.sh'` → `EXIT=1`.
- **Verdict** : mutant ROUGE, comme exigé — la garde protège réellement `mark` contre une
  exception réelle de `subprocess.run` sur un sibling non exécutable. Restauré par
  `git checkout -- plugin/conductor/scripts/dag.sh`, `bash -n` re-vérifié après restauration.

### Mutation n°2 — `check_stall_signal()`

Retiré temporairement le `try/except Exception: return` englobant de `check_stall_signal()`
(même procédure). Fixture : `check-guard-health.sh` isolé `chmod 000` dans un répertoire de test
hors dépôt (`os.path.isfile()` reste vrai sur un fichier `chmod 000` — c'est `subprocess.run` qui
échoue). Appel : `mark --file=... --id=n1 --status=running`.

- **Assertion attendue** : exit 0, aucun crash.
- **Obtenu (mutant)** : `Traceback` → `check_stall_signal` → `subprocess.run` →
  `PermissionError: [Errno 13] Permission denied: '.../check-guard-health.sh'` → `EXIT=1`.
- **Verdict** : mutant ROUGE. Restauré par `git checkout -- plugin/conductor/scripts/dag.sh`,
  suite complète re-passée au vert après restauration (154 PASS / 0 FAIL).

Les deux mutations ont été exécutées dans des répertoires de scratchpad hors du dépôt (jamais
dans `plugin/conductor/scripts/`), `dag.sh` restauré via `git checkout --` immédiatement après
chaque mesure — `git status --porcelain` vérifié vide avant de poursuivre.

## Comptage avant/après

| Suite | Avant ce plan | Après ce plan |
|---|---|---|
| `test-dag.sh` | 123 PASS / 0 FAIL | **154 PASS / 0 FAIL** (31 assertions neuves : T41×6, T42×6, T43×5, T44×2, T45×3, T46×4, T47×5) |
| `test-driver-lock.sh` (non-régression) | 183 PASS / 0 FAIL | 183 PASS / 0 FAIL (inchangé) |
| `test-check-guard-health.sh` (non-régression) | 75 PASS / 0 FAIL | 75 PASS / 0 FAIL (inchangé) |
| `test-notify.sh` (informationnel, posé par 33-04) | 48 PASS / 0 FAIL / 0 SKIP | 48 PASS / 0 FAIL / 0 SKIP (inchangé — le `chmod +x` de `notify.sh` ne change rien : ce fichier l'invoque via `bash "$NOTIFY"`, jamais en exec direct) |
| `test-vf-portable.sh` (non-régression) | 16 ok | 16 ok (inchangé) |
| `test-guard-driver-lock.sh` (non-régression) | 80 PASS / 0 FAIL | 80 PASS / 0 FAIL (inchangé) |

Découverte complète : `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` → **65**,
inchangé avant/après ce plan (aucune suite neuve ajoutée, `test-dag.sh` était déjà découvert).

**Portée-plan exacte** : `git diff --name-only ce4454f..HEAD` rend exactement
`{plugin/conductor/scripts/dag.sh, plugin/conductor/scripts/notify.sh, plugin/conductor/scripts/tests/test-dag.sh, .planning/phases/VFDO-33-watchdog-notifications-des-missions/33-CLOTURE-WINDOWS.md}`
— sur-ensemble strict du `files_modified` déclaré, l'unique fichier en plus étant `notify.sh`
(déviation documentée ci-dessus). `hooks.json` et `check-capability-activation.sh` : 0 occurrence
dans ce diff, vérifié par grep.

## Aucun toast réel observé

Toutes les invocations réelles de `notify.sh` pendant l'exécution de cette suite (T42/T43/T46, y
compris le contrôle positif direct de la tâche « décision argumentée ») ont eu lieu avec
`VF_NOTIFY_FORCE_CHANNEL=linux` et un `PATH` restreint à un jeu de binaires curés ne contenant
aucun `osascript`/`notify-send`/`terminal-notifier`/`powershell.exe` réel — cette machine est un
vrai macOS et `notify-send` n'y est de toute façon pas installé (vérifié : `command -v
notify-send` échoue), donc même sans la restriction de PATH le channel `linux` forcé n'aurait pu
déclencher aucun canal réel. Aucun toast système n'est apparu pendant l'exécution de la suite
(vérification humaine ponctuelle : aucune notification macOS visible pendant les runs).

## Déviations depuis le plan

1. **[Déviation déclarée] `notify.sh` rendu exécutable (755, était 644)** — cf. section « Décision
   argumentée » ci-dessus. Fichier hors du `files_modified` strict de ce plan, ajouté au diff en
   toute transparence, justifié par une mesure (126 → 0) plutôt qu'une supposition.
2. Aucune autre déviation. L'interface de `notify.sh` (positionnels `<TITLE> <BODY>`, deux
   arguments) correspondait exactement à l'assomption du plan — aucun ajustement de forme d'appel
   nécessaire côté `dag.sh`.
3. L'ordre des appels dans le bloc `mark` (`save(dag)` → `record_progress()` (33-02) →
   `check_stall_signal()` → `record_milestone()`) était déjà conforme côté 33-02 au moment de la
   relecture — aucun réordonnancement nécessaire, seulement l'insertion des deux nouveaux appels
   à la suite.

**Total déviations :** 1 auto-déclarée (permission de fichier, hors périmètre strict mais
justifiée et documentée). **Impact :** aucun sur le comportement fonctionnel prescrit par le
plan — seule la condition d'exécutabilité de `notify.sh` était en cause, pas sa logique.

## Prochaine étape

Dernier plan de la Phase 33 (33-05, wave 3). Les trois dépendances (33-02, 33-03, 33-04) et ce
plan sont maintenant livrés. La clôture Windows (D-33-C) reste une condition ouverte — non un
gate — jusqu'à ce qu'un testeur humain sur Win10/11 rejoue `33-CLOTURE-WINDOWS.md`. Décision
CHANGELOG/VERSION du module `conductor` explicitement déférée au geste de release/clôture de la
Phase 33 (cf. must_haves du plan, précédent Phase 32).
