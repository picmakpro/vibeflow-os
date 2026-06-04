# Spec — Install UX VibeFlow (plugin + skill à toggles)

> Date : 2026-06-04
> Statut : design validé (brainstorming), prêt pour milestone GSD
> Repo : vibeflow-os

## 1. Vision

Réduire l'installation de VibeFlow et de ses modules à **presque aucune étape technique**.
Cible :

```
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
/vibeflow-install
```

Le skill `/vibeflow-install` présente deux listes de toggles dans le terminal — **scope**
(user/project/local) puis **modules** — et installe tout au bon endroit, dépendances
auto-résolues. Aucun clone, aucun script à lancer à la main, aucune édition de `settings.json`.

**Objectif mesurable** : depuis zéro, un utilisateur installe le plugin et obtient les modules
voulus au scope voulu (+ GSD + Superpowers) sans jamais taper de commande shell d'installation
ni cloner de repo.

## 2. Décisions structurantes (verrouillées)

| # | Décision | Choix |
|---|----------|-------|
| ID1 | Bootstrap | Plugin Claude Code (repo = marketplace GitHub) |
| ID2 | Visibilité repo | **Public** (install zéro-auth). Flip `private→public` = étape délibérée et confirmée au shipping |
| ID3 | Packaging | Le plugin **bundle tout** (modules + skill + engine + manifeste) ; le skill copie depuis le cache plugin → scope ; **pas de git clone** |
| ID4 | Scope | **Un seul** choix (user/project/local) appliqué à tout : modules VibeFlow + GSD + Superpowers |
| ID5 | UX interactive | Skill `/vibeflow-install` ; les "toggles" = l'UI de questions du terminal (multi-select) ; scripts minimaux |
| ID6 | Dépendances modules | Auto-résolues + récap avant install ; manifeste **`module.json`** par module (machine-lisible) |
| ID7 | dev-orchestrator 1er usage | Détecte `.planning/` absent → propose map-codebase puis new-project (sur confirmation) |

## 3. Mapping des scopes (ID4)

| Scope | VibeFlow modules | GSD | Superpowers (plugin) |
|-------|------------------|-----|----------------------|
| **user** (global) | `~/.claude/` | `npx … --global` | `--scope user` |
| **project** (commité) | `./.claude/` (suivi git) | `npx … --local` | `--scope project` |
| **local** (gitignored) | `./.claude/` + ajout `.gitignore` | `npx … --local` | `--scope local` |

## 4. Composant — Plugin `vibeflow` (ID1, ID3)

- `.claude-plugin/plugin.json` (manifeste plugin) + `.claude-plugin/marketplace.json` (entrée marketplace).
- Le plugin **bundle** : tous les modules (`consolidator`, `infrastructure-audit`, `validator`,
  `skill-creator`, `reference`, `software-architecture`, `audit-architecture`, `dev-orchestrator`),
  le skill `/vibeflow-install`, l'engine `vibeflow-update.sh`, le manifeste de dépendances.
- Install : `claude plugin marketplace add picmakpro/vibeflow-os` → `claude plugin install vibeflow`.
- Le skill lit les modules depuis le **cache du plugin** (`~/.claude/plugins/cache/.../vibeflow/<v>/`)
  et les copie au scope choisi. MAJ via `claude plugin update vibeflow`.

## 5. Composant — Skill `/vibeflow-install` (ID5, cœur de l'UX)

Skill agent-driven (les toggles = l'UI de questions, pas un TUI bash). Séquence :
1. **Détecte l'environnement** : GSD/Superpowers déjà présents ? modules déjà installés ? scope existant ?
2. **Toggle scope** (single-select) : user / project / local.
3. **Toggle modules** (multi-select) : tous les modules installables + description 1 ligne (depuis `module.json`).
4. **Auto-résout les dépendances** (ID6) → **récap** ("validator entraîne consolidator + infrastructure-audit").
5. **Installe** au scope choisi, en déléguant à l'engine :
   - Modules VibeFlow → engine `install` scope-aware.
   - GSD + Superpowers → `ensure-deps.sh` scopé (si `dev-orchestrator` sélectionné, ou sur demande).
   - Si scope `local` → ajoute les chemins au `.gitignore`.
6. **Récap final** + prochaines étapes (ex. « dis "aide-moi à dev" pour démarrer »).

## 6. Composant — Engine `vibeflow-update.sh` scope-aware (ID3, ID4)

- Paramètre **`VF_SCOPE`** / `--scope user|project|local` → résout `TARGET_ROOT` :
  `user`→`$HOME/.claude`, `project`/`local`→`./.claude` ; `local` ajoute aussi au `.gitignore`.
- **Source = cache du plugin** (variable `VIBEFLOW_CACHE` pointant sur le dossier d'install du plugin)
  au lieu du `git clone` → suppression de la logique `.vibeflow-cache`/`ensure_cache` clone.
- **Résolveur de dépendances** : lit les `module.json`, calcule la fermeture transitive des `requires`.
- `install` / `update` / `uninstall` / `status` deviennent **scope-aware** (cibles selon `TARGET_ROOT`).
- Rétro-compat : un appel sans scope par défaut sur `project` (`./.claude`) = comportement actuel.

## 7. Composant — Manifeste `module.json` + résolveur (ID6)

Chaque module gagne un `module.json` à sa racine :
```json
{
  "name": "validator",
  "version": "v1.1.0",
  "type": "agent-only",
  "description": "Agent garant de l'alignement méthodo ↔ lab (5 audits).",
  "requires": ["consolidator", "infrastructure-audit"]
}
```
Source de vérité machine-lisible (remplace la prose des READMEs). Le skill agrège tous les
`module.json` pour : la liste à toggles (nom + description), et l'auto-résolution (`requires`).

## 8. Composant — `ensure-deps.sh` scopé (ID4)

Aujourd'hui figé `--global` (GSD) / `--scope user` (Superpowers). Devient paramétrable via `VF_SCOPE` :
- GSD : `user`→`--global`, `project`/`local`→`--local`.
- Superpowers : `claude plugin install superpowers@claude-plugins-official --scope <user|project|local>`.
- Idempotence et fallback manuel inchangés.

## 9. Composant — dev-orchestrator first-use detection (ID7)

Étendre `vf-init` / l'agent `vibeflow-dev` : au premier usage, si `.planning/PROJECT.md` (ou
`.planning/`) est **absent**, l'agent le détecte et **propose** : cartographier le code existant
(`gsd-map-codebase`, non-interactif si du code existe) puis démarrer le projet (`gsd-new-project`,
sur confirmation explicite). Ne lance jamais `gsd-new-project` seul (cohérent BOOT-04 du module).

## 10. Découpage en phases (milestone GSD)

- **Phase 1 — Manifeste & résolveur** : `module.json` pour les 8 modules + résolveur de dépendances (fondation, testable isolément).
- **Phase 2 — Engine scope-aware** : `vibeflow-update.sh` (scope/TARGET_ROOT, source cache plugin, intégration résolveur) + `ensure-deps.sh` scopé.
- **Phase 3 — Packaging plugin** : `plugin.json`, `marketplace.json`, bundle, doc d'install ; flip repo public (étape confirmée).
- **Phase 4 — Skill `/vibeflow-install`** : toggles scope + modules, récap dépendances, orchestration engine + GSD + Superpowers.
- **Phase 5 — dev-orchestrator first-use** : détection `.planning/` absent + proposition (extension `vf-init`/agent).

Ordre : 1 → 2 → 3/4 (4 dépend de 1+2 ; 3 packaging peut suivre 4) → 5 (indépendant, peut partir tôt).

## 11. Hors scope (YAGNI)

- Migration automatique d'un scope à l'autre (réinstaller dans l'autre scope = manuel pour l'instant).
- Désinstallation/rollback scope-aware avancée (on garde le comportement actuel, juste cible adaptée).
- UI graphique : on reste CLI/skill-driven.
- Versioning indépendant des modules vs plugin (le plugin embarque une version figée par release).

## 12. Risques / points ouverts

- **Flip public (ID2)** : action quasi-irréversible (contenu visible). À exécuter délibérément en Phase 3, sur confirmation explicite, jamais en douce.
- **`marketplace add` repo privé→public** : valider en Phase 3 que `claude plugin marketplace add picmakpro/vibeflow-os` fonctionne réellement zéro-auth une fois public.
- **Coexistence plugin ↔ modules copiés** : le plugin fournit le skill+engine+cache ; les modules vivent ensuite dans `~/.claude` ou `./.claude` selon scope — vérifier l'absence de double-chargement (skill du plugin vs skills copiés).
