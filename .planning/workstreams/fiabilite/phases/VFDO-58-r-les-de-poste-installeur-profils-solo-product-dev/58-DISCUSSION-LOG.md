# Phase 58: Rôles de poste — installeur, profils solo / product / dev - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-16
**Phase:** 58-roles-de-poste
**Areas discussed:** Modèle du poste, Ce que filtre le poste, Gate/contexte/doctrine, Collision avec Willy et branche

Canal : questions escaladées par `vf-dev-manager` (SendMessage vers la session principale), posées à Samuel par
AskUserQuestion en session principale le 2026-10-16, groupées par zone. Les réponses ont été relayées au manager
le même jour. Recommandation retenue partout.

---

## Modèle du poste

| Q | Options | Selected |
|---|---------|----------|
| Q1 fichier | `.claude/vibeflow-role` (une ligne) · `env.VF_ROLE` dans `settings.local.json` · fichier ignoré sous `.planning/` | `.claude/vibeflow-role` ✓ |
| Q2 liste autorisée | `vf_roles` dans `.planning/config.json` racine · fichier dédié versionné · aucune liste tant que solo | `vf_roles` ✓ |
| Q3 sémantique | solo = sur-ensemble, `[]`/inconnu refusés · solo valeur à part entière · `[]` = caché | solo = sur-ensemble ✓ |
| Q4 scope user | solo sans question · poste par compte · compte + surcharge projet | solo sans question ✓ |

## Ce que filtre le poste

| Q | Options | Selected |
|---|---------|----------|
| Q5 scope project partagé | filtre à la pose + front doors/SessionStart, « une vue, pas un droit » · forcer `local` · deny Skill par utilisateur | « une vue, pas un droit » ✓ |
| Q6 table `roles` | minimale (3 modules) · 17 modules annotés · + design-orchestrator | minimale ✓ |
| Q7 changement de poste | réécrire + avis · désinstallation gatée · refus | réécrire + avis ✓ |
| Q8 `--all` | `install --all` filtre si `VF_ROLE` explicite, `update --all` inchangé · les deux filtrent | premier ✓ |

## Gate, contexte, doctrine

| Q | Options | Selected |
|---|---------|----------|
| Q9 `check-role-consistency.sh` | hook SessionStart + refus installeur, consultatif · hook seul · CI seule | hook + installeur ✓ |
| Q10 contexte SessionStart (A-04) | en 58 par le stdout du hook · en 59 | en 58 ✓ |
| Q11 ADR de doctrine | ADR-077 en 58 · en 59 · note seulement | ADR-077 en 58 ✓ |
| Q12 vocabulaire | renommage doc + glossaire · en l'état | renommage doc ✓ |

## Collision avec Willy et branche

| Q | Options | Selected |
|---|---------|----------|
| Q13 `gitignore_add_paths()` | bloc séparé + rebase · coordination préalable · attendre ses merges | bloc séparé ✓ |
| Q14 branche | empilée sur `docs/cloture-phase-57` · depuis origin/main · attendre le merge de la clôture | empilée ✓ |
