# Requirements: VibeFlow Dev Orchestrator (VFDO)

**Defined:** 2026-06-04
**Core Value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.

## v1 Requirements

### Routing & Agent

- [ ] **ROUT-01**: L'agent `vibeflow-dev` route ≥11 intentions en langage naturel vers le bon skill GSD/superpowers (table de routage).
- [ ] **ROUT-02**: L'agent embarque l'ordre canonique du pipeline GSD + bonnes pratiques (détail dans `references/GSD-PIPELINE.md`, chargé on-demand).
- [ ] **ROUT-03**: L'agent ne nomme jamais « GSD » à l'utilisateur et reframe les sorties en vocabulaire VibeFlow.
- [ ] **ROUT-04**: L'agent est distribué via `AGENT.md` et installé en `.claude/agents/dev-orchestrator.md` par `vibeflow-update.sh`.

### Index GSD

- [x] **IDX-01**: `build-gsd-index.sh` parse les `SKILL.md` des skills `gsd-*` installés → `references/gsd-skills-index.md` (factuel uniquement, aucun nom inventé).
- [x] **IDX-02**: L'index se régénère à l'install/update du module et lors d'un drift GSD détecté.

### Abstraction

- [ ] **ABS-01**: Un set complet de commandes `/vf-*` mappe vers GSD/superpowers/bootstrap, invocables par l'utilisateur ET par l'agent en autonomie.
- [ ] **ABS-02**: Une traduction de vocabulaire masque les termes GSD (ex. « SUMMARY » → « rapport de sprint »).

### Bootstrap auto-install

- [x] **BOOT-01**: `ensure-deps.sh` installe GSD en non-interactif si absent (`npx -y get-shit-done-cc@latest --claude --global`).
- [x] **BOOT-02**: `ensure-deps.sh` installe Superpowers en non-interactif si absent (`claude plugin install superpowers@claude-plugins-official --scope user`).
- [x] **BOOT-03**: `ensure-deps.sh` est idempotent, vérifie les exit codes, et affiche les étapes manuelles uniquement si un prérequis (Node/npm ou CLI `claude`) manque.
- [x] **BOOT-04**: `gsd-new-project` (interactif) ne se lance jamais seul ; l'agent propose l'init sur confirmation ; `map-codebase` peut tourner auto si du code existe.

### Vérification

- [ ] **VERIF-01**: `tests/test-dev-orchestrator.sh` couvre génération d'index, idempotence de `ensure-deps`, couverture du routage, mapping `/vf-*` non orphelin.
- [ ] **VERIF-02**: Gates de densité respectés (agent ≤250L, skills ≤500L), vérifiés par `wc -l` dans le test du module (`check-file-size.sh` n'audite pas les `.md` : regex code sans `.md`).

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
| ROUT-01 | Phase 1 | Pending |
| ROUT-02 | Phase 1 | Pending |
| ROUT-03 | Phase 1 | Pending |
| ROUT-04 | Phase 1 | Pending |
| IDX-01 | Phase 1 | Complete |
| IDX-02 | Phase 1 | Complete |
| ABS-01 | Phase 1 | Pending |
| ABS-02 | Phase 1 | Pending |
| BOOT-01 | Phase 1 | Complete |
| BOOT-02 | Phase 1 | Complete |
| BOOT-03 | Phase 1 | Complete |
| BOOT-04 | Phase 1 | Complete |
| VERIF-01 | Phase 1 | Pending |
| VERIF-02 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-04*
*Last updated: 2026-06-04 after initial definition*
