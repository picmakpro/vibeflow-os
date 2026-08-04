---
phase: 23
slug: couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: false
wave_0_complete: true
created: 2026-08-01
validated: 2026-08-04
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

> **RENSEIGNÉ A POSTERIORI, le 2026-08-04.** Ce document est resté le gabarit brut pendant toute
> l'exécution de la phase : les huit plans ont été exécutés, revus et soldés sans qu'aucun
> contrat d'échantillonnage ne soit écrit ici. Les chiffres ci-dessous sont **mesurés par
> exécution** au moment du remplissage, pas reconstitués de mémoire. La conséquence est assumée
> et visible dans le frontmatter : `status: validated` (les comportements SONT couverts et
> prouvés) mais `nyquist_compliant: false` (la **latence** de rétroaction n'a pas été contractée
> pendant l'exécution — voir §Sign-off). Écrire `true` ici serait précisément le défaut que
> cette phase traque : une affirmation de conformité que rien n'a mesurée.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + assertions maison (pas de framework tiers — les livrables sont des scripts shell et de la doctrine) |
| **Config file** | none — infrastructure préexistante, aucune Wave 0 nécessaire |
| **Quick run command** | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` |
| **Full suite command** | `find plugin -path '*/tests/test-*.sh' -exec bash {} \;` (forme exacte de la CI : `.github/workflows/ci.yml`, job « Suites de tests (découverte non vide) ») |
| **Estimated runtime** | ~25 s pour la suite du module, ~90 s pour les 46 suites du dépôt |

---

## Sampling Rate

- **After every task commit:** `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`
- **After every plan wave:** la suite du module **+** `test-check-gsd-config.sh` et `test-check-gsd-engine.sh`
- **Before `/gsd-verify-work`:** les 46 suites du dépôt vertes
- **Max feedback latency:** 25 s (suite du module)

---

## Per-Task Verification Map

Contractée **par exigence** et non par tâche : les huit plans de cette phase livrent de la doctrine
et des gates, dont la vérification est portée par des blocs de test nommés, pas par un test unitaire
adossé à une fonction. Chaque ligne est prouvée par exécution, pas par lecture.

| Requirement | Plan | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---|---|---|---|---|---|---|
| GSDC-01 — contrat de checkpoint relayé, jamais recalculé | 23-01 | — | un checkpoint refusé par le moteur ne peut pas être tranché par l'équipe | bloc | `test-dev-orchestrator.sh` | ✅ green |
| GSDC-02 — `_auto_chain_active` remis à `false` au démarrage | 23-01 | — | pas d'exécution hors frontière DAG héritée d'un `--auto` antérieur | bloc | `test-dev-orchestrator.sh` | ✅ green |
| GSDC-03 — doctrine de flags en allowlist stricte | 23-03 | — | aucun flag hors allowlist ne peut être passé au moteur | bloc | `test-dev-orchestrator.sh` | ✅ green |
| GSDC-04 — table capabilities/hooks **générée** depuis le moteur | 23-04 | T-23-04-07 | le générateur LIT le moteur sans jamais l'exécuter (anti-RCE) | bloc + mutation | `test-dev-orchestrator.sh` | ✅ green |
| GSDC-05 — voie unique d'invocation des briques de cycle | 23-05 | — | plus de dispatch d'agent nu qui désactiverait la moitié du moteur en silence | bloc | `test-dev-orchestrator.sh` | ✅ green |
| GSDC-06 — arbitrage des doublons d'étage (extension ADR-061) | 23-06 | — | l'étage superposé est tranché explicitement, pas par omission | bloc | `test-dev-orchestrator.sh` | ✅ green |
| GSDC-07 — `check-gsd-config.sh` signale toute clé inconnue | 23-02 | T-23-02-03, T-23-02-07 | union à 3 sources, parseur linéaire, aucune exécution du moteur | suite dédiée | `test-check-gsd-config.sh` | ✅ green |
| GSDC-08 — briques dormantes : moment déclencheur écrit | 23-07 | — | volet dispatch couvert ; **volet allowlist ouvert sur `D-22`** | bloc | `test-dev-orchestrator.sh` | ⚠️ partiel |
| GSDC-09 — un budget de tours **par étape**, partagé | 23-07 | — | deux boucles ne peuvent plus additionner leurs budgets | bloc | `test-dev-orchestrator.sh` | ✅ green |
| GSDC-10 — bump minor du module + gouvernance | 23-08 | T-23-08-01 | aucun fichier de version **racine** dans le diff de branche | bloc | `test-dev-orchestrator.sh` | ✅ green |

**Comptes mesurés le 2026-08-04** (exécution, pas mémoire — le compteur de cette suite a menti cinq
fois sur cette phase, chaque progression a été recoupée par ensembles de libellés) :

| Suite | Résultat |
|---|---|
| `test-dev-orchestrator.sh` | **161 OK / 0 KO / 0 SKIP** (102 avant la phase) |
| `test-check-gsd-config.sh` | **37 ok / 0 ko** (suite créée par 23-02) |
| `test-check-gsd-engine.sh` | **15 ok / 0 ko** (suite créée par 23-01) |
| Dépôt entier | **46 suites, 0 échec** |

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* Les trois suites concernées préexistaient
ou ont été créées par les plans eux-mêmes (23-01 pour `test-check-gsd-engine.sh`, 23-02 pour
`test-check-gsd-config.sh`) ; aucune installation de framework n'a été nécessaire.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|---|---|---|---|
| Écart `D-22` — `gsd-debugger` présent dans `vf-coder.md` contre une décision « aucune exception », **et** exigé par le gate `T19` | GSDC-08 | Contradiction entre une décision et un gate : la trancher demande un arbitrage humain, aucun test ne peut choisir lequel des deux a tort | Trancher D-22, puis retirer l'entrée **et** son assertion dans `T19` d'un même geste — les deux se corrigent ensemble ou la suite rougit |
| Les six gestes de release racine (bump `VERSION`, tag annoté, release GitHub) | GSDC-10 | Gate humain non négociable (`CLAUDE.md`) ; `T-23-08-01` garantit seulement que la branche n'y touche pas | `bash scripts/check-release-tag.sh --remote` après la release |
| Canari CI de forme du moteur GSD | GSDC-04 | N'avait **jamais tourné sur un runner réel** au moment de la clôture (`gh run list` vide pour toute la phase) — il ne prouve rien tant qu'un run ne l'a pas exercé | Vérifier sur le premier run vert de la PR que l'étape « canari de forme » est bien exécutée et discriminante |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies — 10 exigences sur 10 adossées à une commande
- [ ] **Sampling continuity: no 3 consecutive tasks without automated verify** — *non contractable a posteriori.* La continuité d'échantillonnage est une propriété de la **conduite** de l'exécution ; ce document n'existait pas pendant celle-ci, donc rien n'a pu la mesurer au fil de l'eau. C'est la seule case que ce remplissage rétroactif ne peut pas cocher honnêtement, et c'est elle qui maintient `nyquist_compliant: false`.
- [x] Wave 0 covers all MISSING references — aucune référence manquante
- [x] No watch-mode flags — aucune suite n'utilise de mode veille
- [x] Feedback latency < 25 s — mesurée sur la suite du module
- [ ] `nyquist_compliant: true` set in frontmatter — **délibérément laissé à `false`** (voir ci-dessus)

**Approval:** validated 2026-08-04 — *avec la réserve Nyquist ci-dessus, et l'écart `D-22` ouvert.*
