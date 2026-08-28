---
name: vibeflow-install
description: Utiliser au tout premier lancement de VibeFlow après l'installation du plugin (l'utilisateur lance manuellement `/vibeflow-install`), ou quand l'utilisateur dit « installe VibeFlow », « configure les modules », « ajoute un module », « change de scope », « re-configure VibeFlow », « désinstalle un module », « désinstalle VibeFlow », « retire tout », ou veut choisir où installer (compte / projet / projet sans commit). Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vibeflow-install — Orchestration de l'install à toggles

Skill **orchestrateur thin** : il décrit la séquence d'UX et **DÉLÈGUE** à des briques déjà
livrées (catalogue, résolveur de deps, engine scope-aware, bootstrap GSD/Superpowers). Il ne
réimplémente RIEN — pas de TUI bash, pas de logique de copie, pas de gitignore maison.

Ce skill est de la **PROSE agent-driven** : le routage/UX réel se valide en session (comme le
first-use). Seules les briques déléguées sont testées unitairement.

## Câblage du cache (à appliquer pour CHAQUE délégation — étapes 0, 1, 3, 4, 5)

En contexte plugin, Claude Code fournit `${CLAUDE_PLUGIN_ROOT}` : le chemin absolu du dossier
d'install du plugin (= le **cache**). C'est là que vivent les modules, leurs `module.json` à la
racine, et le dossier `_internal/` (engine + résolveur + `merge-hooks.sh`, le câbleur de hooks ADR-043). L'engine attend ce chemin dans deux
variables :

- `VIBEFLOW_CACHE` — source unique du cache pour `vibeflow-update.sh` (`status`, `install`).
- `VF_MODULES_ROOT` — racine des modules pour `build-module-catalog.sh` et `resolve-deps.sh`.

**Convention de résolution (avec fallback dev)** — toujours exporter ces variables ainsi avant
de déléguer à un script :

```sh
VIBEFLOW_CACHE="${CLAUDE_PLUGIN_ROOT:-<racine du repo vibeflow-os cloné en dev>/plugin}"
VF_MODULES_ROOT="${CLAUDE_PLUGIN_ROOT:-<racine du repo vibeflow-os cloné en dev>/plugin}"
```

- **En plugin installé** : `${CLAUDE_PLUGIN_ROOT}` est défini → les deux variables pointent sur le
  cache bundlé.
- **En dev (repo cloné, pas plugin)** : `CLAUDE_PLUGIN_ROOT` est absent → le fallback pointe les
  deux variables sur le sous-dossier `plugin/` du repo `vibeflow-os` (qui contient les modules +
  `_internal/`). Comportement déjà supporté par les scripts : `VF_MODULES_ROOT` défaut =
  `$(dirname "$0")/..` qui résout précisément sur `plugin/` ; `VIBEFLOW_CACHE` défaut
  `.vibeflow-cache`, donc en dev on le pointe explicitement sur `plugin/`.

**Chemins réels des briques dans le cache** — les scripts ne sont PAS à la racine du cache et le
repo contient une dizaine de dossiers `scripts/` différents : **toujours invoquer par le chemin
complet ci-dessous, jamais par le nom nu** (un nom nu force l'exécutant à deviner le dossier —
bug d'install vécu sur le terrain, ADR-054) :

| Brique | Invocation exacte |
|---|---|
| Préflight prérequis (étape 0) | `bash "$VIBEFLOW_CACHE/installer/scripts/preflight.sh"` |
| Catalogue modules (étapes 3–4) | `VF_MODULES_ROOT="$VIBEFLOW_CACHE" bash "$VIBEFLOW_CACHE/installer/scripts/build-module-catalog.sh"` |
| Résolveur de deps (étape 5) | `VF_MODULES_ROOT="$VIBEFLOW_CACHE" bash "$VIBEFLOW_CACHE/_internal/resolve-deps.sh" <modules…>` |
| Engine status/install/uninstall | `VIBEFLOW_CACHE="$VIBEFLOW_CACHE" bash "$VIBEFLOW_CACHE/_internal/vibeflow-update.sh" …` |
| Bootstrap GSD/Superpowers (étape 5, branche dev) | `VF_SCOPE=<s> bash "$VIBEFLOW_CACHE/dev-orchestrator/scripts/ensure-deps.sh"` |

`_internal/resolve-deps.sh` est **bundlé dans le plugin** (présent dans le cache `${CLAUDE_PLUGIN_ROOT}`)
→ `--with-deps` fonctionne réellement après une install plugin (lève le warning Phase 3).

## Séquence

0. **Préflight prérequis (ADR-054).** Lancer `bash "$VIBEFLOW_CACHE/installer/scripts/preflight.sh"`.
   S'il échoue (exit 1) : montrer TEL QUEL le diagnostic `[preflight]` à l'utilisateur (il contient
   la commande d'installation par OS — ex. Windows : `winget install jqlang.jq`) et **S'ARRÊTER LÀ**.
   S'il passe (exit 0) mais émet des lignes `⚠` : les montrer aussi (limitations runtime à connaître).
   Ne jamais tenter le catalogue ni une install avec un prérequis dur manquant.

1. **Détection environnement.** GSD / Superpowers présents ? Modules déjà installés
   (engine `status` — invocation exacte dans la table « Chemins réels » ci-dessus) ? Un scope déjà
   utilisé précédemment ? **Le cwd est-il un repo git ?** (`git rev-parse --is-inside-work-tree`)
   — cette détection **pré-sélectionne** le scope de l'étape 2. Elle sert à pré-cocher / informer,
   pas à décider à la place de l'utilisateur.

2. **Scope pré-sélectionné (INST-01 — confirmation en une touche).** Ne PAS poser un choix à
   froid entre 3 options que le nouvel utilisateur ne sait pas arbitrer : la détection (étape 1)
   **pré-sélectionne** —
   - cwd = repo git → **`project` pré-coché** ;
   - pas de repo git → **`user` pré-coché** ;
   - un scope déjà utilisé précédemment (registre) **prime** sur la règle git.

   La question devient une **confirmation** via l'UI de questions du terminal (AskUserQuestion /
   toggles, **PAS** un TUI bash) : le choix pré-coché en première option + **une ligne
   d'explication** du pourquoi (ex. « Ce dossier est un repo git → j'installe dans le projet,
   versionné avec lui. On confirme ? »), les autres scopes en options secondaires — dont `local`
   (projet sans commit), expliqué d'une ligne s'il est affiché. Un et un seul scope est retenu
   (cohérence **ID4** : le même scope s'applique à tout — modules VibeFlow + GSD + Superpowers).
   Reframe pour l'utilisateur : compte (user) / projet (project) / projet sans commit (local).

3. **Baseline obligatoire — posée d'office (INST-02a).** Lire le catalogue
   (invocation exacte dans la table « Chemins réels » ci-dessus) : il émet `name<TAB>description<TAB>role`.
   Les entrées **`role == mandatory`** (aujourd'hui : `conductor`, le gardien méta du lab, et
   `consolidator`, le socle de mémoire) sont posées **automatiquement** avec leurs deps — **on ne
   les met PAS dans un toggle** : un lab sans son orchestrateur méta n'a pas de filet de cohérence,
   et un lab sans registres ne capitalise rien (principe 1 de VibeFlow). On **informe** l'utilisateur
   (« je pose le socle de gouvernance et de mémoire »), on ne lui demande pas de choisir.
   **Aucun nom de module en dur** : la liste des mandatory sort du catalogue (`role`).

4. **Choix du type de lab (INST-02b — single-select).** Une fois le socle posé, **un seul** choix
   structurant, via l'UI de questions (pas un TUI bash) :
   - **Lab de développement** → poser le module `dev-orchestrator` (entrée `optional` du catalogue)
     + amorcer ses dépendances de dev.
   - **Nouveau lab (autre métier)** → ne rien poser de plus ici : la suite passe par **`/vf-new-lab`**
     (porté par `conductor`, déjà posé), qui mène la clarification du métier et **câble lui-même**
     les modules pertinents (auditeurs, planning, etc.). On ne présume jamais « dev ».

   > **Ne JAMAIS proposer un métier figé (growth, content, business…) comme s'il était prêt.** Les
   > bundles métier incomplets sont marqués `proposable:false` → ils n'apparaissent même pas au
   > catalogue. Le seul chemin métier offert est `vf-new-lab`, qui construit le lab sur mesure.
   >
   > **À-la-carte avancé (optionnel).** Un utilisateur averti qui demande explicitement un module
   > `optional` précis (ex. « ajoute kpi-analyst ») peut l'obtenir — on liste alors les entrées
   > `optional` du catalogue. Ce n'est PAS le chemin par défaut du premier usage.

5. **Install scopée (INST-04 — déléguée, scope unique partout).** Résoudre la fermeture transitive
   des `requires` via le résolveur (invocation exacte dans la table ci-dessus) et **récapituler** ce qui
   sera posé **AVANT** d'installer (ex. « conductor entraîne planning-core + validator + skill-creator »).
   - **Plan avant pose (MANI-02, issue #20)** → même invocation, préfixée `--dry-run` :
     `VIBEFLOW_CACHE="$VIBEFLOW_CACHE" bash "$VIBEFLOW_CACHE/_internal/vibeflow-update.sh" --scope <s> --dry-run install --with-deps <module>`.
     Afficher la sortie TELLE QUELLE (c'est du stdout, capturable sans les diagnostics stderr) : le
     plan fichier-par-fichier qui enrichit le récapitulatif ci-dessus. `--dry-run` n'écrit rien et
     est refusé sur `uninstall` — il ne protège pas ce verbe-là.
   - **Modules VibeFlow** → `VIBEFLOW_CACHE="$VIBEFLOW_CACHE" bash "$VIBEFLOW_CACHE/_internal/vibeflow-update.sh" --scope <s> install --with-deps <module>`
     (conductor d'office, puis `dev-orchestrator` si branche dev).
     `--with-deps` recâble lui-même le résolveur côté engine.
   - **GSD + Superpowers** → `VF_SCOPE=<s> bash "$VIBEFLOW_CACHE/dev-orchestrator/scripts/ensure-deps.sh"`
     (uniquement si `dev-orchestrator` est posé, ou sur demande).
     **PASSER TOUJOURS un VF_SCOPE explicite** = `<s>` (cohérence **ID4**).
   - Scope `local` → le `.gitignore` est géré **par l'engine** (SCOPE-04, déjà fait) : ne pas le
     réimplémenter, juste le mentionner à l'utilisateur (« rien ne sera committé »).

6. **Récap final + prochaine étape (context-aware).** Confirmer ce qui a été posé et où, puis amorcer
   la suite selon la branche choisie :
   - **Branche dev** → « dis "aide-moi à dev" pour démarrer ».
   - **Branche nouveau lab** → enchaîner sur **`/vf-new-lab [métier]`** (ou inviter l'utilisateur à le
     lancer) pour la phase de clarification et la construction du lab sur mesure.

## Désinstallation (déléguée — même câblage de cache)

Quand l'utilisateur veut **retirer** un ou tous les modules, déléguer à l'engine (jamais de `rm`
manuel) avec **le même `VIBEFLOW_CACHE` et le même `--scope`** que pour l'install — le scope DOIT
correspondre à celui où les modules ont été posés (sinon l'engine cherche au mauvais endroit).

- **Un module** :
  `VIBEFLOW_CACHE="$VIBEFLOW_CACHE" bash "$VIBEFLOW_CACHE/_internal/vibeflow-update.sh" --scope <s> uninstall <module>`
  — **sauf un module `mandatory`** (conductor, consolidator) : ne pas le retirer à l'unité (ils
  portent la gouvernance et la mémoire du lab). Ils ne partent qu'avec une désinstallation complète
  (`uninstall --all`). Si l'utilisateur insiste, le prévenir de ce qu'il perd : l'orchestrateur méta
  pour `conductor`, les registres et les guards de capitalisation pour `consolidator` — les fichiers
  déjà écrits dans `.claude/memory/` restent, mais plus rien ne les tient.
- **Tout** :
  `VIBEFLOW_CACHE="$VIBEFLOW_CACHE" bash "$VIBEFLOW_CACHE/_internal/vibeflow-update.sh" --scope <s> uninstall --all`
  (lit le registre `<scope>/.claude/scripts/.vibeflow-installed` et retire chaque module : skills,
  agent + references D7, scripts et rules qui lui appartiennent ; backup automatique avant chaque
  retrait).

> **Ordre critique à rappeler à l'utilisateur (ORDRE-01).** Pour une désinstallation *complète* de
> VibeFlow, retirer les **modules d'abord** (`uninstall --all`), **puis** le plugin
> (`claude plugin uninstall vibeflow`). Si le plugin part en premier, le cache
> `${CLAUDE_PLUGIN_ROOT}` disparaît et l'engine ne peut plus identifier les scripts/rules à
> retirer proprement. GSD/Superpowers (dépendances externes) ne sont **jamais** désinstallés
> automatiquement — le préciser et laisser le choix à l'utilisateur.

## Garde-fous

- **`VF_SCOPE` explicite partout** : ne jamais s'appuyer sur le défaut LEGACY de l'engine
  (`project`) ni de `ensure-deps.sh` (`user`). Un scope unique, choisi une fois, propagé à
  l'engine **et** à `ensure-deps.sh` (ID4).
- **Scope pré-sélectionné, jamais un choix à froid** : la détection (repo git → `project`, sinon
  `user`, scope précédent prioritaire) pré-coche ; l'utilisateur **confirme en une touche** avec
  une ligne d'explication — il garde toujours la main pour choisir un autre scope.
- **Baseline non négociable** : tout module `role=mandatory` du catalogue (conductor, consolidator)
  est posé d'office, jamais soumis à un toggle. Le premier usage offre **un seul** choix structurant —
  *lab de développement* vs *nouveau lab métier (`vf-new-lab`)* — pas une liste brute de modules.
- **Jamais proposer un module `proposable:false`** : exclu du catalogue par construction (bundles
  métier WIP). Ne le reproposer qu'une fois finalisé (repasser `proposable` à true / l'omettre).
- **Ne réimplémente jamais** une brique : route et délègue (catalogue, `resolve-deps.sh`,
  `vibeflow-update.sh --scope`, `ensure-deps.sh` via `VF_SCOPE` — invocations exactes : table
  « Chemins réels » ci-dessus).
- **Reframe en vocabulaire VibeFlow** ; ne nomme jamais GSD ni Superpowers à l'utilisateur
  (cohérent vf-init / ABS-02).
