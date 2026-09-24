# Requirements: VibeFlow Dev Orchestrator (VFDO) — gouvernance-labs-v1.0

**Defined:** 2026-09-23

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FABR-01 | Phase 42 | Complete |
| FABR-02 | Phase 42 | Complete |
| FABR-03 | Phase 42 | Pending — inscrite 2026-09-23 (cadrage `42-CONTEXT.md`) |
| FABR-04 | Phase 42 | Pending — inscrite 2026-09-23 (cadrage `42-CONTEXT.md`) |
| FABR-05 | Phase 42 | Pending — inscrite 2026-09-23 (cadrage `42-CONTEXT.md`) |

## Milestone gouvernance-labs-v1.0 — « le planning métier tenu par une machine » (inscrit 2026-09-23)

> Polarité gouvernance (Willy). Sources : `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md`,
> `2026-09-22-moteur-planning-metier-design.md`, `2026-09-23-initialisation-lab-design.md`. Préfixe `FABR`
> vérifié libre par `grep -rn 'FABR-' .planning/ plugin/ docs/` le 2026-09-23 (seule occurrence : le
> cadrage `42-CONTEXT.md` qui les propose). Les phases 43 à 50 recevront leurs familles à leur cadrage.

### Fabrique — manifeste daté et invariants du gate des agents (Phase 42)
- [x] **FABR-01**: Les listes de référence de `check-agents.sh` (outils, champs de frontmatter, types natifs, modèles, modes de permission, niveaux d'effort) vivent dans un manifeste daté versionné, source unique sans copie de repli dans le script ; chaque liste porte sa date de vérification et sa source ; un manifeste absent ou illisible est un refus explicite (`42-CONTEXT.md` D-01, D-03)
- [x] **FABR-02**: Un manifeste périmé (au-delà de la validité qu'il déclare) rend le gate INDÉTERMINÉ (exit 3) en CI du dépôt, un avertissement chez l'utilisateur (hook `SessionStart`, garde d'écriture), et ne peut jamais refuser sur une liste fermée (D-02, D-04, D-05)
- [ ] **FABR-03**: Le gate refuse les violations des invariants I1 à I7 selon les définitions D-06 à D-09 (I2/I3 sous `--resolve-agents=strict` seulement) ; chaque invariant naît avec son jumeau négatif, dont la mutation est prouvée rouge
- [ ] **FABR-04**: La découverte des agents est récursive, et ses exclusions (fichiers qui ne sont pas des agents) sont prouvées par un cas de test (D-10)
- [ ] **FABR-05**: Le corpus d'agents du dépôt passe `--strict` et `--resolve-agents=strict` avec les invariants armés ; un commit par module touché avec son bump de patch ; le test qui verrouillait une affirmation périmée sur la profondeur de dispatch est corrigé (D-11, D-12, D-13)
