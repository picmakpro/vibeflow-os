---
name: vibeflow-install
description: >
  Utiliser au tout premier lancement de VibeFlow après l'installation du plugin (l'utilisateur
  lance manuellement `/vibeflow-install`), ou quand l'utilisateur dit
  « installe VibeFlow », « configure les modules », « ajoute un module », « change de scope »,
  « re-configure VibeFlow », « désinstalle un module », « désinstalle VibeFlow », « retire tout »,
  ou veut choisir où installer (compte / projet / projet sans commit).
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vibeflow-install — Orchestration de l'install à toggles

Skill **orchestrateur thin** : il décrit la séquence d'UX et **DÉLÈGUE** à des briques déjà
livrées (catalogue, résolveur de deps, engine scope-aware, bootstrap GSD/Superpowers). Il ne
réimplémente RIEN — pas de TUI bash, pas de logique de copie, pas de gitignore maison.

Ce skill est de la **PROSE agent-driven** : le routage/UX réel se valide en session (comme le
first-use). Seules les briques déléguées sont testées unitairement.

## Câblage du cache (à appliquer pour CHAQUE délégation — étapes 1, 3, 4, 5)

En contexte plugin, Claude Code fournit `${CLAUDE_PLUGIN_ROOT}` : le chemin absolu du dossier
d'install du plugin (= le **cache**). C'est là que vivent les modules, leurs `module.json` à la
racine, et le dossier `_internal/` (engine + résolveur). L'engine attend ce chemin dans deux
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

Concrètement, par étape :

- **étape 1 (status)** : `VIBEFLOW_CACHE="${CLAUDE_PLUGIN_ROOT:-…}" vibeflow-update.sh status`
- **étape 3 (catalogue)** : `VF_MODULES_ROOT="${CLAUDE_PLUGIN_ROOT:-…}" build-module-catalog.sh`
- **étape 4 (résolveur)** : `VF_MODULES_ROOT="${CLAUDE_PLUGIN_ROOT:-…}" resolve-deps.sh …`
- **étape 5 (install)** :
  `VIBEFLOW_CACHE="${CLAUDE_PLUGIN_ROOT:-…}" vibeflow-update.sh --scope <s> install --with-deps <module>`

`_internal/resolve-deps.sh` est **bundlé dans le plugin** (présent dans le cache `${CLAUDE_PLUGIN_ROOT}`)
→ `--with-deps` fonctionne réellement après une install plugin (lève le warning Phase 3).

## Séquence

1. **Détection environnement.** GSD / Superpowers présents ? Modules déjà installés
   (`vibeflow-update.sh status`, avec `VIBEFLOW_CACHE` = cache du plugin) ? Un scope déjà
   utilisé précédemment ? Sert à pré-cocher / informer, pas à décider à la place de l'utilisateur.

2. **Toggle scope (INST-01 — single-select).** Proposer **un seul** choix parmi
   `user` / `project` / `local`, via l'UI de questions du terminal (AskUserQuestion / toggles),
   **PAS** un TUI bash. Un et un seul scope est retenu (cohérence **ID4** : le même scope
   s'applique à tout — modules VibeFlow + GSD + Superpowers). Reframe pour l'utilisateur :
   compte (user) / projet (project) / projet sans commit (local).

3. **Toggle modules (INST-02 — multi-select).** Peupler la liste à partir de
   `build-module-catalog.sh` (`VF_MODULES_ROOT` = cache du plugin) : chaque entrée = nom + la
   description 1 ligne issue de son `module.json`. **Aucun nom de module en dur** — tout sort du
   catalogue.

4. **Auto-résolution + récap (INST-03).** Passer la sélection à `resolve-deps.sh`
   (`VF_MODULES_ROOT` = cache) pour la **fermeture transitive** des `requires`, puis
   **RÉCAPITULER explicitement** à l'utilisateur ce que ça entraîne (ex. « validator entraîne
   aussi consolidator + infrastructure-audit ») **AVANT** toute install. L'utilisateur voit la
   liste complète des modules qui seront posés.

5. **Install scopée (INST-04 — déléguée, scope unique partout).**
   - **Modules VibeFlow** → `vibeflow-update.sh --scope <s> install --with-deps <module>` (ou
     itérer la fermeture déjà résolue), avec `VIBEFLOW_CACHE` pointant sur le cache du plugin.
     `--with-deps` recâble lui-même le résolveur côté engine.
   - **GSD + Superpowers** → `VF_SCOPE=<s> ensure-deps.sh` (si dev-orchestrator est sélectionné,
     ou sur demande). **PASSER TOUJOURS un VF_SCOPE explicite** = `<s>`, le scope choisi à
     l'étape 2 (cohérence **ID4** — on ne laisse jamais le défaut LEGACY décider).
   - Scope `local` → le `.gitignore` est géré **par l'engine** (SCOPE-04, déjà fait) : ne pas le
     réimplémenter, juste le mentionner à l'utilisateur (« rien ne sera committé »).

6. **Récap final + prochaines étapes.** Confirmer ce qui a été posé et où, puis amorcer la suite
   en vocabulaire VibeFlow (ex. « dis "aide-moi à dev" pour démarrer »).

## Désinstallation (déléguée — même câblage de cache)

Quand l'utilisateur veut **retirer** un ou tous les modules, déléguer à l'engine (jamais de `rm`
manuel) avec **le même `VIBEFLOW_CACHE` et le même `--scope`** que pour l'install — le scope DOIT
correspondre à celui où les modules ont été posés (sinon l'engine cherche au mauvais endroit).

- **Un module** :
  `VIBEFLOW_CACHE="${CLAUDE_PLUGIN_ROOT:-…}" vibeflow-update.sh --scope <s> uninstall <module>`
- **Tout** :
  `VIBEFLOW_CACHE="${CLAUDE_PLUGIN_ROOT:-…}" vibeflow-update.sh --scope <s> uninstall --all`
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
- **Ne réimplémente jamais** une brique : route et délègue (catalogue, `resolve-deps.sh`,
  `vibeflow-update.sh --scope`, `ensure-deps.sh` via `VF_SCOPE`).
- **Reframe en vocabulaire VibeFlow** ; ne nomme jamais GSD ni Superpowers à l'utilisateur
  (cohérent vf-init / ABS-02).
