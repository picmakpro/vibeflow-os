---
name: vibeflow-install
description: >
  Utiliser au tout premier lancement de VibeFlow après l'installation du plugin (le hook
  SessionStart de 1er lancement invoque ce skill automatiquement), ou quand l'utilisateur dit
  « installe VibeFlow », « configure les modules », « ajoute un module », « change de scope »,
  « re-configure VibeFlow », ou veut choisir où installer (compte / projet / projet sans commit).
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vibeflow-install — Orchestration de l'install à toggles

Skill **orchestrateur thin** : il décrit la séquence d'UX et **DÉLÈGUE** à des briques déjà
livrées (catalogue, résolveur de deps, engine scope-aware, bootstrap GSD/Superpowers). Il ne
réimplémente RIEN — pas de TUI bash, pas de logique de copie, pas de gitignore maison.

Ce skill est de la **PROSE agent-driven** : le routage/UX réel se valide en session (comme le
first-use). Seules les briques déléguées sont testées unitairement.

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

## Garde-fous

- **`VF_SCOPE` explicite partout** : ne jamais s'appuyer sur le défaut LEGACY de l'engine
  (`project`) ni de `ensure-deps.sh` (`user`). Un scope unique, choisi une fois, propagé à
  l'engine **et** à `ensure-deps.sh` (ID4).
- **Ne réimplémente jamais** une brique : route et délègue (catalogue, `resolve-deps.sh`,
  `vibeflow-update.sh --scope`, `ensure-deps.sh` via `VF_SCOPE`).
- **Reframe en vocabulaire VibeFlow** ; ne nomme jamais GSD ni Superpowers à l'utilisateur
  (cohérent vf-init / ABS-02).
