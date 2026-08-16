# 31-04 — SUMMARY : `--dry-run`, le flag demandé par l'issue #20 (MANI-02)

**Exécuté par** : `vf-coder` (inline, `execute-plan.md`), sur mandat de `vf-dev-manager`.
**Branche** : `feat/phase-31-manifeste-dry-run` (HEAD de départ `7126535`, jamais `main`).

## Ce qui a été livré

1. **Surface du flag (D-31-06)** : `VF_DRY_RUN` + `vf_dry_run()`, parsés dans le MÊME pré-parse
   que `--scope` (donc valides avant `cmd="$1"`). Accepté sur `install`/`update` (toutes formes,
   avant ou après le verbe). Refusé, exit 1, message nommant le verbe reçu ET les deux verbes
   acceptés, sur `uninstall`/`rollback`/`status`/`sync`.
2. **Rendu + neutralisation (D-31-01/04/05)** : `vf_declare_write` porte désormais la branche
   `--dry-run` — un seul point de bascule, sur le MÊME chemin de code que la pose. Tous les sites
   d'écriture de 31-03 (`vf_place_file`, `vf_place_tree`, `copy_engine_lib`, `backup_module`,
   `merge_module_hooks`, `gitignore_add_one`, `mark_installed`, `vf_manifest_flush`,
   `cleanup_retired_modules`, `vf_manifest_reset`) court-circuitent avant d'écrire.
3. **Les trois régimes (D-31-04)** :
   - **A** (sortie prédite, sous-processus non appelé) : `generate-agent-commands.sh`,
     `build-gsd-index.sh`, `build-gsd-capabilities-index.sh`.
   - **B** (preview déléguée) : `merge_module_hooks` appelle `merge-hooks.sh plan` (livré en
     31-02) au lieu de `merge`, mêmes flags — sa sortie stdout est relayée telle quelle.
   - **C** (effet annoncé, non énuméré) : `seed-registres.sh`, `inject-mcp-tools.sh`,
     `ensure-design-deps.sh`.
4. **Format de sortie (D-31-05)** : `[plan] + <chemin TARGET_ROOT-préfixé>  (<module> <version>)`
   pour les créations sans note, `[plan] <verbe> <chemin>  <note>` sinon, plan sur **stdout**,
   diagnostics sur **stderr** — vérifié positivement et négativement (aucune ligne `[plan] ` sur
   stderr).
5. **Deux preuves distinctes de MANI-02** dans `test-manifest.sh` (32/32, 8 cas nouveaux TD1-TD8).

## Déviation signalée : nommage des cas de test (TD1-TD8, pas T10-T14)

Le plan (31-04-PLAN.md) désignait les nouveaux cas `T10`/`T10b`/`T11`/`T12`/`T13`/`T13b`/`T13c`/
`T14`. **Ces noms sont déjà pris** dans `test-manifest.sh` par les cas B1-B4/M2/M6 livrés en
31-03 (injection de panne réelle sur `vf_place_tree`/`rules`/`scripts/tests`/`scripts`, et le
gel des dotfiles côté POSE, `T7b`) — le plan a été écrit sans relire l'état réel du fichier après
31-03. Réutiliser ces libellés aurait **écrasé des tests discriminants existants** sous les mêmes
noms (deux blocs de code différents partageant un même identifiant `ok "T10 : …"` dans le même
fichier — confusion certaine en cas d'échec futur, et le premier `T10` du fichier aurait été
purement et simplement remplacé). J'ai renommé la nouvelle série `TD1`…`TD8` (Test Dry-run), en
conservant l'ORDRE et l'INTENTION exacts du plan (`TD1`=T10 du plan, `TD2`=T10b, …, `TD8`=T14) —
la correspondance est documentée en tête de fichier ET sur chaque bloc. Remonté ici en zone grise
pour arbitrage a posteriori si le nommage doit être revu.

## Piège de garde (D-31-04) — 5 sites corrigés, pas 4

Le plan en citait 5 : `build-gsd-index.sh`, `build-gsd-capabilities-index.sh`,
`ensure-design-deps.sh`, `seed_module_registres` (`[ -f "$seeder" ]`), et la cascade de
`find_command_generator`. **En creusant le mécanisme de la cascade**, j'ai trouvé un **6e site du
même piège**, non nommé par le plan : `find_mcp_injector`/`inject_lab_mcp_into_agents` (régime
C, ADR-051) a EXACTEMENT la même cascade « `$TARGET_ROOT/scripts/…` en premier, repli cache
ensuite ». Sans le neutraliser, un `--dry-run install` sur un lab vierge aurait **réellement
exécuté** `inject-mcp-tools.sh` via le repli cache (le premier candidat, absent, aurait fait
tomber sur le second, présent) — un sous-processus de régime C tournant pour de vrai sous
`--dry-run`. Corrigé par le même patron que `generate_agent_command_for` (court-circuit avant
tout appel à `find_mcp_injector`, sur la garde SOURCE déjà établie par l'appelant).

## Bug latent trouvé et corrigé : `~` non quoté = expansion tilde

Les 8 sites appelant `vf_declare_write ~ "$dest" "note"` (verbe `~` non quoté) subissaient
l'expansion tilde de bash : `~` seul, non quoté, en position d'argument, s'étend en `$HOME` AVANT
que la fonction ne soit appelée. En mode réel, ce bug était **inoffensif par hasard** (le `case`
de `vf_declare_write` ne fait rien ni pour `~` ni pour toute autre valeur non `+`/`-`) — mais en
`--dry-run`, il faisait imprimer `[plan] /Users/<user> <chemin> …` au lieu de `[plan] ~ <chemin>
…`. Corrigé en quotant les 8 sites (`"~"`). Trouvé par test manuel AVANT l'écriture de la suite —
sans ce test manuel, `TD4`/`TD5` auraient pu passer à tort sur un format cassé (le texte cherché
ne dépend pas du caractère `~`).

## `mkdir -p` hors des helpers — 3 sites additionnels neutralisés

`vf_place_file`/`vf_place_tree`/`copy_engine_lib`/`backup_module` court-circuitent AVANT leur
propre `mkdir -p`, mais 3 appels `mkdir -p` vivaient EN DEHORS de ces helpers, dans
`copy_module_scripts` (×2 : `$TARGET_ROOT/scripts`, `$TARGET_ROOT/scripts/tests/fixtures`) et
dans la boucle `rules/*.md` d'`install_module` (`$TARGET_ROOT/rules`). Trouvé par test manuel
(empreinte `find` avant/après sur un lab vierge, `comm -3` non vide) : sans le fix, un
`--dry-run install software-architecture` créait `./.claude`, `./.claude/rules`,
`./.claude/scripts`, `./.claude/scripts/tests` — répertoires vides mais RÉELLEMENT créés,
violation directe de D-31-06 (« n'écrit rien du tout »). Corrigé par `vf_dry_run || mkdir -p …`.

## Preuve d'égalité totale (TD1) — mesurée, pas supposée

```
LAB_PLAN (dry-run) vs LAB_REEL (install réel), même CACHE, software-architecture :
comm -23 REEL PLAN  → vide (rien manqué au plan)
comm -13 REEL PLAN  → vide (rien annoncé en trop)
```
17 chemins de chaque côté, ensembles strictement identiques (rules/, scripts/, scripts/tests/,
skills/…/references/, settings.json, settings.local.json, .vibeflow-installed,
.vibeflow-manifest-software-architecture, vf-portable.sh). Aucune exception négociée dans le
corps du test TD1 (`grep -c 'grep -v'` sur le bloc = 0).

## Comportement sur les 4 verbes refusés

```
$ bash vibeflow-update.sh --dry-run uninstall foo   → rc=1, stderr nomme "uninstall" + "install"/"update"
$ bash vibeflow-update.sh --dry-run rollback foo    → rc=1, idem
$ bash vibeflow-update.sh --dry-run status          → rc=1, idem
$ bash vibeflow-update.sh --dry-run sync            → rc=1, idem
```
`--dry-run` placé APRÈS le verbe (`install --dry-run <mod>`) également reconnu (pré-parse balaie
toute la ligne). Cas `$# = 0` : usage imprimé, exit 0 (comportement antérieur conservé).

## Traces des 3 mutations rouges (Tâche 3)

Chaque mutation : appliquée sur `vibeflow-update.sh`, suite rejouée, trace capturée, puis
restauration prouvée par `cmp` (identité octet à octet avec la copie de référence).

### Mutation 1 — TD2 (régime A, discriminance)
- **Site muté** : `generate_agent_command_for`, branche `vf_dry_run` — suppression de l'unique
  `vf_declare_write + "$TARGET_ROOT/commands/${mod}.md"`.
- **Assertion** : `TD2` (présence de 3 lignes régime A sur `dev-orchestrator`, lab vierge).
- **Attendu** : les 3 lignes présentes (`commands/dev-orchestrator.md`, `gsd-skills-index.md`,
  `gsd-capabilities-index.md`).
- **Obtenu (rouge)** : `✗ TD2 : au moins une ligne régime A absente du plan` — la sortie capturée
  ne contient plus AUCUNE ligne `commands/dev-orchestrator.md` (les deux lignes d'index restent,
  car portées par un site distinct non muté) → `31 OK / 1 KO`.
- **Restauration** : `cmp` sur `vibeflow-update.sh` avant/après revert → identique (md5
  `0c157f653d98c90ce728452b1939a2df` des deux côtés).

### Mutation 2 — TD3 (arbre inchangé, discriminance mandatée par le plan)
- **Site muté** : `vf_place_file`, branche `vf_dry_run` — suppression du `return 0` après
  `vf_declare_write + "$dest"` (l'annonce reste, mais l'exécution continue vers `mkdir`/`cp`).
- **Assertion** : `TD3` (empreinte `find` du lab entier identique avant/après `--dry-run`, scope
  local).
- **Attendu** : `before == after`.
- **Obtenu (rouge)** : `✗ TD3 : le lab a changé pendant un --dry-run` — 7 chemins créés en trop
  (rules/, scripts/, scripts/tests/, SKILL.md) → `30 OK / 2 KO` (bonus : `TD1` rougit aussi sur
  le même mutant, preuve croisée que l'égalité totale est elle aussi discriminante sur ce site).
- **Restauration** : `cmp` identique après revert, suite revenue à `32 OK / 0 KO`.

### Mutation 3 — TD7 (gel des dotfiles, discriminance)
- **Premier essai (mutant mort, consigné honnêtement)** : neutraliser SEULEMENT le `case "$name"
  in .*) continue ;; esac` de `vf_place_tree` ne fait PAS rougir `TD7` — la boucle
  `for entry in "$src_dir"/*` n'énumère JAMAIS les dotfiles en premier lieu (`dotglob` non armé,
  comportement par défaut de bash 3.2/macOS) : le filtre explicite double une exclusion déjà
  produite par le glob lui-même. Vérifié : suite rejouée après cette première mutation → `32 OK /
  0 KO`, TD7 toujours vert. Mutant mort, reporté plutôt que maquillé.
- **Second essai (discriminant)** : glob étendu `"$src_dir"/* "$src_dir"/.[!.]*` (simule un
  dotglob accidentel) EN PLUS du filtre neutralisé.
- **Assertion** : `TD7` (aucune ligne `.hidden-marker` au plan, fixture `skill-creator` +
  `.hidden-marker` injecté).
- **Attendu** : 0 ligne `.hidden-marker`.
- **Obtenu (rouge)** : `✗ TD7 : le dotfile de premier niveau est annoncé au plan à tort` — la
  sortie capturée contient `[plan] + ./.claude/skills/skill-creator/.hidden-marker  (skill-creator
  v1.0.3)` → `31 OK / 1 KO`.
- **Restauration** : `cmp` identique après revert, suite revenue à `32 OK / 0 KO`.

## Résultat des trois suites (arbre TEL QUE COMMITÉ, `git archive HEAD`)

```
test-manifest.sh        : 32 OK / 0 KO / 0 SKIP
test-vibeflow-update.sh : 19 OK / 0 KO / 0 SKIP
test-merge-hooks.sh     : 32 OK · 0 KO
```
`bash -n vibeflow-update.sh` : 0. `scripts/check-machine-paths.sh` : ✓ 1033 fichiers, 0 chemin
absolu.

## Commits

- `plugin/_internal/vibeflow-update.sh` : flag + rendu + neutralisation des trois régimes.
- `plugin/_internal/tests/test-manifest.sh` + ce SUMMARY : TD1-TD8, deux preuves de MANI-02.

## Ce que je n'ai PAS fait (hors périmètre du mandat)

- Câblage des skills consommateurs (`/vibeflow-install`, `/vf-calibrate`) — D-31-10, dernière
  vague explicitement séparée (31-08 selon le DAG), pas dans le périmètre fichiers de ce mandat.
- `update --dry-run` sur le chemin « version inchangée » (`sync_module_governance`) : les sites
  qu'il appelle (`copy_engine_lib`, `copy_module_scripts`, `merge_module_hooks`,
  `seed_module_registres`) sont TOUS neutralisés et fonctionnels en dry-run, mais
  `sync_module_governance` n'appelle jamais `vf_manifest_reset` (par construction, D-31-14) —
  donc `VF_MANIFEST_MOD` peut être vide sur ce chemin précis, et le suffixe `(<module>
  <version>)` d'une éventuelle ligne `copy_engine_lib` y serait incomplet (`(  )`). Aucun fixture
  de ce mandat n'exerce ce chemin (T10-TD8 passent tous par `install`, jamais par un `update` à
  version inchangée) — signalé en zone grise, pas corrigé faute de test qui le couvre et pour ne
  pas étendre le périmètre du mandat sans mandat.

## Addendum — correction ciblée (findings fusionnés revue + vérification `--dry-run`)

Mandat de correction ciblée sur les findings F-01/F-02/F-04/F-06/F-08 + durcissement
`mark_uninstalled`. Résumé (détail : `git log`, commit qui suit ce SUMMARY) :

- **F-01 corrigé** : la garde du backup `settings.json` dans `merge_module_hooks` testait le
  DISQUE, aveugle à l'effet d'un module antérieur du MÊME run en multi-module (`--all`/
  `--with-deps`) — `install --all --dry-run` sur 2 modules à `hooks.json` annonçait 0 backup là où
  la pose réelle en crée 1. Nouveau drapeau run-scoped `VF_SETTINGS_JSON_WILL_EXIST` (miroir de
  `VF_ENGINE_LIB_COPIED`), initialisé sur l'état réel du disque puis mis à jour au fil du run.
  Mesuré : 0/1 → 1/1 (plan == réel). Test `TD9`.
- **F-02 corrigé** — exactement la zone grise signalée ci-dessus : `sync_module_governance` pose
  désormais `VF_MANIFEST_MOD` (sans ouvrir de cycle, D-31-14 intact — même garde que la branche
  dry-run de `vf_manifest_reset`) au lieu de laisser le suffixe tomber à `( —)`. Mesuré sur
  `update --all --dry-run` (2 modules, version inchangée) : 27/27 lignes `( —)` → 0/27. Test
  `TD10`.
- **F-04 partiellement corrigé** : `.vibeflow-installed` annonce désormais `+` sur lab vierge
  (était `~`, fausse déclaration de modification pour une création) — `mark_installed`, test
  `TD11`. `settings.json`/`settings.local.json` (même défaut) sortent du périmètre STRICT de ce
  mandat : leur verbe est câblé en dur (`[plan] ~ …`) dans `merge-hooks.sh` ligne 444, un fichier
  hors des deux chemins autorisés — **non corrigé**, remonté pour un mandat séparé.
- **F-06 corrigé** : `--dry-run=<valeur>` sort désormais avec un message dédié nommant la forme
  refusée, au lieu de retomber dans le fourre-tout d'usage générique. Test `TD12`.
- **F-08 corrigé** : légende de `TD5` réécrite (tête de fichier + bloc de test) — elle ne prouve
  que la moitié « absent du manifeste » de l'exclusion D-31-03 sur régime C, pas l'asymétrie
  plan/manifeste complète (portée par TD4+TD5 ensemble). Le test lui-même n'a pas changé.
- **`mark_uninstalled` durci** : garde interne `vf_dry_run && return 0` ajoutée, symétrique de
  `mark_installed` — les 2 appelants existants gataient déjà correctement, durcissement préventif
  contre un futur appelant (D-31-09) sans garde externe propre.
- **Couverture manquante comblée** : `TD13` — `--scope user`, chemin du plan absolu et résolu
  (HOME isolé sous `fakehome`, jamais le vrai `$HOME`), aucune écriture.
- **F-03, F-05 : non corrigés, documentés** (par mandat explicite — comportement fidèle au réel,
  amélioration de lisibilité seulement demandée). Pas de note ajoutée sur `.backups/<mod>-<TS>`
  dans cette passe (F-03) : laissé pour un mandat de forme dédié, aucun risque de sûreté identifié.

**Les 5 nouveaux cas (`TD9`-`TD13`) sont prouvés discriminants par mutation** (chacun rougit sur
le revert de son correctif, restauration `cmp` identique après revert). Trois suites vertes
(`test-manifest.sh` 37 OK/0 KO, `test-vibeflow-update.sh` 19 OK/0 KO,
`test-merge-hooks.sh` 32 OK/0 KO), les deux gates repo à 0 lancés nus.
