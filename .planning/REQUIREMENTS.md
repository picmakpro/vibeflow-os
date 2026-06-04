# Requirements: VibeFlow Dev Orchestrator (VFDO)

**Defined:** 2026-06-04
**Core Value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.

## v1 Requirements

### Routing & Agent

- [x] **ROUT-01**: L'agent `vibeflow-dev` route ≥11 intentions en langage naturel vers le bon skill GSD/superpowers (table de routage).
- [x] **ROUT-02**: L'agent embarque l'ordre canonique du pipeline GSD + bonnes pratiques (détail dans `references/GSD-PIPELINE.md`, chargé on-demand).
- [x] **ROUT-03**: L'agent ne nomme jamais « GSD » à l'utilisateur et reframe les sorties en vocabulaire VibeFlow.
- [x] **ROUT-04**: L'agent est distribué via `AGENT.md` et installé en `.claude/agents/dev-orchestrator.md` par `vibeflow-update.sh`.

### Index GSD

- [x] **IDX-01**: `build-gsd-index.sh` parse les `SKILL.md` des skills `gsd-*` installés → `references/gsd-skills-index.md` (factuel uniquement, aucun nom inventé).
- [x] **IDX-02**: L'index se régénère à l'install/update du module et lors d'un drift GSD détecté.

### Abstraction

- [x] **ABS-01**: Un set complet de commandes `/vf-*` mappe vers GSD/superpowers/bootstrap, invocables par l'utilisateur ET par l'agent en autonomie.
- [x] **ABS-02**: Une traduction de vocabulaire masque les termes GSD (ex. « SUMMARY » → « rapport de sprint »).

### Bootstrap auto-install

- [x] **BOOT-01**: `ensure-deps.sh` installe GSD en non-interactif si absent (`npx -y get-shit-done-cc@latest --claude --global`).
- [x] **BOOT-02**: `ensure-deps.sh` installe Superpowers en non-interactif si absent (`claude plugin install superpowers@claude-plugins-official --scope user`).
- [x] **BOOT-03**: `ensure-deps.sh` est idempotent, vérifie les exit codes, et affiche les étapes manuelles uniquement si un prérequis (Node/npm ou CLI `claude`) manque.
- [x] **BOOT-04**: `gsd-new-project` (interactif) ne se lance jamais seul ; l'agent propose l'init sur confirmation ; `map-codebase` peut tourner auto si du code existe.

### Vérification

- [x] **VERIF-01**: `tests/test-dev-orchestrator.sh` couvre génération d'index, idempotence de `ensure-deps`, couverture du routage, mapping `/vf-*` non orphelin.
- [x] **VERIF-02**: Gates de densité respectés (agent ≤250L, skills ≤500L), vérifiés par `wc -l` dans le test du module (`check-file-size.sh` n'audite pas les `.md` : regex code sans `.md`).

## Milestone 2 — Install UX (active)

> Spec : `docs/superpowers/specs/2026-06-04-install-ux-design.md`

### Manifeste & résolveur (Phase 2)

- [x] **MANIF-01**: Chaque module a un `module.json` (name, version, type, description, `requires[]`) — source machine-lisible.
- [x] **MANIF-02**: Un résolveur calcule la fermeture transitive des `requires` (ex. validator → consolidator + infrastructure-audit).

### Engine scope-aware (Phase 3)

- [x] **SCOPE-01**: `vibeflow-update.sh` accepte `--scope user|project|local` → résout `TARGET_ROOT` (`~/.claude` vs `./.claude`).
- [x] **SCOPE-02**: Source des modules = cache du plugin (plus de `git clone .vibeflow-cache`).
- [x] **SCOPE-03**: `ensure-deps.sh` scopé : GSD `--global`/`--local`, Superpowers `--scope user|project|local`.
- [x] **SCOPE-04**: Scope `local` → ajout des chemins installés au `.gitignore`.

### Skill /vibeflow-install + auto-lancement (Phase 4)

- [x] **INST-01**: Toggle scope (single-select user/project/local).
- [x] **INST-02**: Toggle modules (multi-select) avec description issue des `module.json`.
- [x] **INST-03**: Récap des dépendances auto-résolues avant install.
- [x] **INST-04**: Orchestration de l'install au scope choisi (modules + GSD + Superpowers).
- [x] **INST-05**: Hook `SessionStart` + marqueur de 1er lancement → ouvre l'UX automatiquement (ID8).

### Packaging plugin (Phase 5)

- [ ] **PLUG-01**: `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` valides.
- [ ] **PLUG-02**: Le plugin bundle modules + skill + engine + manifeste.
- [ ] **PLUG-03**: Repo `vibeflow-os` rendu public (étape délibérée confirmée).
- [ ] **PLUG-04**: `claude plugin marketplace add` + `install` fonctionnent en zéro-auth (validé).

### dev-orchestrator first-use (Phase 6)

- [ ] **FIRST-01**: L'agent détecte l'absence de `.planning/` (projet non GSD-initialisé) au 1er usage.
- [ ] **FIRST-02**: Il propose map-codebase puis new-project sur confirmation (jamais `gsd-new-project` seul).

## v2 Requirements

### Vocabulaire & UX

- **VOC-01**: Traduction exhaustive de tous les artefacts GSD en vocabulaire VibeFlow.
- **VOC-02**: Migration automatique `get-shit-done-cc` → `@opengsd/gsd-core` quand la bascule npm est stable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Fork/réécriture des skills GSD | On délègue ; absorber casserait les mises à jour gratuites de GSD |
| Support multi-runtime custom (Copilot/Gemini) | Déjà géré par GSD ; hors périmètre VibeFlow |
| UI/dashboard | CLI-first, cohérent avec l'écosystème |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ROUT-01 | Phase 1 | Complete |
| ROUT-02 | Phase 1 | Complete |
| ROUT-03 | Phase 1 | Complete |
| ROUT-04 | Phase 1 | Complete |
| IDX-01 | Phase 1 | Complete |
| IDX-02 | Phase 1 | Complete |
| ABS-01 | Phase 1 | Complete |
| ABS-02 | Phase 1 | Complete |
| BOOT-01 | Phase 1 | Complete |
| BOOT-02 | Phase 1 | Complete |
| BOOT-03 | Phase 1 | Complete |
| BOOT-04 | Phase 1 | Complete |
| VERIF-01 | Phase 1 | Complete |
| VERIF-02 | Phase 1 | Complete |
| MANIF-01 | Phase 2 | Complete |
| MANIF-02 | Phase 2 | Complete |
| SCOPE-01 | Phase 3 | Complete |
| SCOPE-02 | Phase 3 | Complete |
| SCOPE-03 | Phase 3 | Complete |
| SCOPE-04 | Phase 3 | Complete |
| INST-01 | Phase 4 | Complete |
| INST-02 | Phase 4 | Complete |
| INST-03 | Phase 4 | Complete |
| INST-04 | Phase 4 | Complete |
| INST-05 | Phase 4 | Complete |
| PLUG-01 | Phase 5 | Pending |
| PLUG-02 | Phase 5 | Pending |
| PLUG-03 | Phase 5 | Pending |
| PLUG-04 | Phase 5 | Pending |
| FIRST-01 | Phase 6 | Pending |
| FIRST-02 | Phase 6 | Pending |

**Coverage:**
- Milestone 1 (v1) : 14 requirements — Complete ✓
- Milestone 2 (Install UX) : 17 requirements — mappés aux phases 2-6, 0 non-mappé ✓

---
*Requirements defined: 2026-06-04*
*Last updated: 2026-06-04 after initial definition*
