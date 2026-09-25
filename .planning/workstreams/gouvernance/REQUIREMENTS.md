# Requirements: VibeFlow Dev Orchestrator (VFDO) — gouvernance-labs-v1.0

**Defined:** 2026-09-23

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FABR-01 | Phase 42 | Complete |
| FABR-02 | Phase 42 | Complete |
| FABR-03 | Phase 42 | Complete — 42-05 (I1,I4,I5,I6,I7) + 42-06 (I2,I3 monde fermé) ; cochée à la main (`requirements.mark-complete` résout vers `fiabilite` sur ce dépôt) |
| FABR-04 | Phase 42 | Complete — 42-06 (découverte récursive D-10) ; cochée à la main |
| FABR-05 | Phase 42 | Complete — 42-02/42-03/42-05/42-06 (corpus conforme, T76 déjà correct depuis v2.63.2 D-13) ; cochée à la main |
| FABR-06 | Phase 43 | Pending |
| FABR-07 | Phase 43 | Pending |
| FABR-08 | Phase 43 | Pending |
| FABR-09 | Phase 43 | Pending |
| FABR-10 | Phase 43 | Pending |

## Milestone gouvernance-labs-v1.0 — « le planning métier tenu par une machine » (inscrit 2026-09-23)

> Polarité gouvernance (Willy). Sources : `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md`,
> `2026-09-22-moteur-planning-metier-design.md`, `2026-09-23-initialisation-lab-design.md`. Préfixe `FABR`
> vérifié libre par `grep -rn 'FABR-' .planning/ plugin/ docs/` le 2026-09-23 (seule occurrence : le
> cadrage `42-CONTEXT.md` qui les propose). Les phases 43 à 50 recevront leurs familles à leur cadrage.

### Fabrique — manifeste daté et invariants du gate des agents (Phase 42)
- [x] **FABR-01**: Les listes de référence de `check-agents.sh` (outils, champs de frontmatter, types natifs, modèles, modes de permission, niveaux d'effort) vivent dans un manifeste daté versionné, source unique sans copie de repli dans le script ; chaque liste porte sa date de vérification et sa source ; un manifeste absent ou illisible est un refus explicite (`42-CONTEXT.md` D-01, D-03)
- [x] **FABR-02**: Un manifeste périmé (au-delà de la validité qu'il déclare) rend le gate INDÉTERMINÉ (exit 3) en CI du dépôt, un avertissement chez l'utilisateur (hook `SessionStart`, garde d'écriture), et ne peut jamais refuser sur une liste fermée (D-02, D-04, D-05)
- [x] **FABR-03**: Le gate refuse les violations des invariants I1 à I7 selon les définitions D-06 à D-09 (I2/I3 sous `--resolve-agents=strict` seulement) ; chaque invariant naît avec son jumeau négatif, dont la mutation est prouvée rouge
- [x] **FABR-04**: La découverte des agents est récursive, et ses exclusions (fichiers qui ne sont pas des agents) sont prouvées par un cas de test (D-10)
- [x] **FABR-05**: Le corpus d'agents du dépôt passe `--strict` et `--resolve-agents=strict` avec les invariants armés ; un commit par module touché avec son bump de patch ; le test qui verrouillait une affirmation périmée sur la profondeur de dispatch est corrigé (D-11, D-12, D-13)

### Fabrique — gate des skills par nature et alignement de skill-creator (Phase 43)
- [ ] **FABR-06**: `check-skills.sh` (nouveau, miroir de `check-agents.sh`, contrat de sortie 0/1/3 identique, F13) refuse tout `SKILL.md` déclaré `vf-nature: procedure` (frontmatter `vf-nature: referentiel | outil | procedure`, défaut « outil ») qui n'a ni bloc `ecrit:` ni rubrique de juge ; un `SKILL.md` `procedure` avec les deux passe (`43-CONTEXT.md` D-Q1, D-Q2)
- [ ] **FABR-07**: `check-skills.sh` détecte l'écart entre la déclaration factuelle en frontmatter (gate bloquant / livrable remis à un tiers / couche de qualité) et des motifs de forme procédurale trouvés indépendamment dans la prose du corps, et le signale en avertissement (exit 0, diagnostic imprimé) — jamais en refus (exit 1) — pour cette phase ; le corpus existant en dérive n'est pas corrigé ici (D-Q1, D-Q5)
- [ ] **FABR-08**: `plugin/skill-creator/skills/skill-creator/SKILL.md` (moteur interne) ET `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` (workflow templaté) posent chacun la question `vf-nature`, avec le même défaut « outil », sans fusionner cette question avec l'étape existante « nature du sujet » (D-Q2, D-Q6)
- [ ] **FABR-09**: `check-instruction-budget.sh` (socle repris, pas de réécriture) refuse tout `SKILL.md` sous `plugin/*/skills/**/SKILL.md` au-delà de 500 lignes et tout bootstrap au-delà de 2000 tokens estimés (ADR-029), avec le même manifeste daté que la Phase 42 étendu des listes propres aux skills, et un checkpoint humain explicite si cette extension fait monter la baseline du budget d'instructions (G-1) (D-Q4)
- [ ] **FABR-10**: `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §1.2/§7.2 est amendé (compte exact de 4 agents `vf-mcp-consumer: true`, `vf-reviewer` cité comme consommateur Xcode, reformulation « deux besoins distincts » conforme à ADR-051 décision 1) ; `inject-mcp-tools.sh` refuse une valeur `vf-mcp-tools` malformée au lieu d'un no-op silencieux (durcissement a, T22) ; `inject-mcp-tools.sh` signale un serveur nommé absent de l'union des scopes projet+global au lieu d'un no-op silencieux (durcissement b, T16, jugé contre l'union ADR-051-B) ; les textes ne nommant que `vf-mcp-consumer` (`plugin/_internal/vibeflow-update.sh:1276,1308,2413`, `plugin/conductor/skills/vf-calibrate/SKILL.md:92`) mentionnent aussi `vf-mcp-tools` (durcissement c) (D-Q3)
