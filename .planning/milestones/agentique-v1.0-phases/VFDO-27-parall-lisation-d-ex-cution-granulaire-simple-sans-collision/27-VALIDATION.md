---
phase: 27
slug: parall-lisation-d-ex-cution-granulaire-simple-sans-collision
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-05
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash maison, patron `test-*.sh` — pas de framework tiers (jest/pytest absent de ce dépôt) |
| **Config file** | aucun fichier de config centralisé — chaque `test-*.sh` est autonome |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-dag.sh` (Livrable 3) ; `bash plugin/conductor/scripts/tests/test-check-agents.sh` (Livrable 2) |
| **Full suite command** | pas de script de suite agrégée global identifié — patron observé : rejeu manuel de toutes les `test-*.sh` avant release |
| **Estimated runtime** | ~10 secondes (suites bash ciblées, pas de suite lourde) |

---

## Sampling Rate

- **After every task commit:** Run la suite bash directement concernée par le fichier touché (`test-dag.sh` pour Livrable 3, `test-check-agents.sh` pour Livrable 2)
- **After every plan wave:** Run l'ensemble des suites `plugin/conductor/scripts/tests/*.sh` touchées par la phase
- **Before `/gsd-verify-work`:** Suite complète verte, plus la preuve d'exécution du spike (Livrable 4) documentée dans l'artefact de décision — pas seulement une lecture de code
- **Max feedback latency:** ~30 secondes

---

## Per-Task Verification Map

> **Réalignée suite à revue (M7)** — la table précédente mappait `27-01=doctrine`, `27-04=spike`,
> `27-05=mesure` : ce n'est pas la découpe finale des plans. La correspondance réelle Plan ↔ Livrable
> est : `27-01=Livrable 3 (dag.sh)` · `27-02=Livrable 1 (doctrine)` · `27-03=Livrable 2 (isolation)` ·
> `27-04=Livrable 5, volet « avant » (baseline)` · `27-05=Livrable 4 (spike)` · `27-06=Livrable 5,
> volet « après » (mesure)`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-02-01 | 02 | 1 | Livrable 1 (doctrine) | — | `team-kernel.md:64-68` ne contient plus « perdu », `.planning/ROADMAP.md` porte le résultat re-dérivé | non testable par machine — grep de non-régression | `grep -c "perdu" plugin/conductor/references/team-kernel.md` (doit décroître) | ✅ (fichiers existants) | ⬜ pending |
| 27-03-01/02/03 | 03 | 1 | Livrable 2 (isolation) | T-27-03-* | `.worktreeinclude` posé, `isolation: worktree` sur les 13 agents écrivains, gate `check-agents.sh` valide, portée écrite (`27-ISOLATION-PORTEE.md`) | unitaire | `bash plugin/conductor/scripts/check-agents.sh` && `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ✅ existant | ⬜ pending |
| 27-01-01/02/03 | 01 | 1 | Livrable 3 (dag.sh) | T-27-01-* | `dag.sh ready` calcule/expose la disjonction par étage (`stages`), sans casser le contrat existant `{ready,count}` | unitaire | `bash plugin/conductor/scripts/tests/test-dag.sh` | ✅ existant — cas T25-T30 ajoutés par ce plan (nœuds à scope recouvrant) | ⬜ pending |
| 27-04-01/02 | 04 | 2 | Livrable 5, volet « avant » (baseline) | T-27-04-* | Baseline d'horloge du dispatch inline capturée **avant** toute activation, corpus étalon versionné et prouvé parallélisable | unitaire (parallélisabilité du corpus) + manuel (capture d'horloge) | `node ~/.claude/gsd-core/bin/gsd-tools.cjs claude-orchestration emit-workflow --waves 27-mesure/waves-toy.json --run-id mesure-27-baseline` | ❌ Wave 0 : `27-mesure/waves-toy.json` et `27-MESURE-GAIN.md` n'existent pas encore | ⬜ pending |
| 27-05-01/02/03 | 05 | 3 | Livrable 4 (spike) | T-27-05-* | Gate ladder + run Workflow réel + sous-expérience Décision A, critères PASS/FAIL écrits à l'avance respectés | unitaire (gate ladder) + manuel/spike (run réel, checkpoint bloquant tâche 2) | `node ~/.claude/gsd-core/bin/gsd-tools.cjs claude-orchestration detect-backend` | ⚠️ pas de test dédié dans ce dépôt — à créer au Wave 0 | ⬜ pending |
| 27-06-01/02 | 06 | 4 | Livrable 5, volet « après » (mesure) | T-27-06-* | Bloc 3 de `27-MESURE-GAIN.md` rempli (A/B contrôlé sous checkpoint, ou non-mesurabilité motivée) | manuel — mesure d'horloge, pas un test automatisable | — | ❌ Wave 0 : le bloc 3 (structure posée par `27-04`) n'est rempli qu'ici | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `plugin/conductor/scripts/tests/test-dag.sh` — ajouter des cas neufs : deux nœuds `ready` avec `scope[]` recouvrant, vérifier qu'ils sortent dans des étages distincts après le câblage (Livrable 3)
- [ ] Un script/note de spike dédié pour le Livrable 4 — pas un test automatisé classique, un protocole reproductible à 3 étapes (gate ladder seul → run réel trivial → sous-expérience Décision A)
- [ ] Le document de méthode de mesure du Livrable 5 (`27-0X-MESURE-GAIN.md` ou équivalent) — n'existe pas encore

*Toute l'infrastructure de test des Livrables 1-3 existe déjà (`test-dag.sh`, `test-check-agents.sh`) — seuls les Livrables 4 et 5 nécessitent une création Wave 0 complète.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Run Workflow réel aboutit (Livrable 4, étape 2 du spike) | Livrable 4 | Nécessite l'outil Workflow réel de la session, pas une simulation — le gate n°4 n'est qu'un proxy de présence, pas une preuve de réponse | Manifeste jouet à 2 plans disjoints, `isolation: worktree`, dispatch via le script émis par `emitWorkflowScript` ; vérifier que les deux artefacts existent, un commit par worker, aucune collision, run terminé sans intervention humaine |
| Sous-expérience Décision A (mur ADR-031 sous Workflow) | Livrable 4 | Le comportement d'un `AskUserQuestion` en cours de run Workflow ne peut être observé que par exécution réelle, pas par lecture de code | Manifeste à un plan dont le `brief` demande explicitement une question utilisateur ; observer si le run échoue explicitement ou remonte le besoin dans le rapport de fin de run (jamais un « faux terminé » silencieux) |
| Baseline d'horloge avant activation (Livrable 5) | Livrable 5 | Mesure de temps réel d'un dispatch, pas un comportement testable en isolation | Chronométrer un dispatch en mode inline actuel sur ≥ 2 plans disjoints, au moins 2 répétitions, avant toute activation de `claude_orchestration` |
| Mesure après activation (Livrable 5) | Livrable 5 | Idem, sous le mode activé | Même volume de travail sous `claude_orchestration` activé, au moins 2 répétitions, dépendance `--deps=` sur la tâche baseline |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
