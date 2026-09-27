# Mission Phase 42 (jalon gouvernance-labs-v1.0) — rapport détaillé

**Manager :** vf-dev-manager (owner `vf-dev-manager-gouv42-20260924`) · **Dates :** 2026-09-24 → 2026-09-25
**Branche :** `gouvernance/phase-42-fabrique` (worktree `.claude/worktrees/gouvernance-42`) · **PR :** #108
**DAG :** `.planning/missions/2026-09-24-gouvernance-42.dag.json` · **Compartiment :** `gouvernance`

## Verdict

**`passed`, en attente de la revue code owner.** La Phase 42 est exécutée (6/6 plans), vérifiée
(`gsd-verifier` 5/5 must-haves, FABR-01 à FABR-05), revue, auditée et corrigée. La condition posée par
Samuel en ratifiant D-08 (e568307) est exécutée, et le contournement du budget d'instructions a été
tranché par l'option (b) (« arbitrage Willy, AskUserQuestion session principale, 2026-09-25 »).
**La PR #108 est sortie du brouillon.** Pas de merge, pas de tag, pas de release (aucune release
gouvernance avant la clôture de `fiabilite-v1.0`).

Le merge attend la relecture de Samuel :
- chemins CODEOWNERS : `.github/workflows/ci.yml` et `.planning/instruction-budget-baselines.tsv`, hausse de +1 sur trois lignes ;
- modules de sa polarité ;
- écart vf-dev-manager → vf-design-judge.

D-12 et `42-VERIFICATION.md` (`status: human_needed`) le relevaient déjà.

## Arbitrage du budget d'instructions (2026-09-25), résolu

Option (b), « arbitrage Willy, AskUserQuestion session principale, 2026-09-25 ». Correction
`fix-42-condition-2` en quatre commits :
- 71677a4 et e28e129 : « interdits du lab » rétabli, même formulation chez growth et design, et doublon F1 retiré.
- 4b72e3c : baseline montée de +1 sur exactement trois lignes, citation dans le commit.
- 7dc6a29 : F2 et l'épisode « garde-fous » consignés dans 42-05-SUMMARY.md.

Revue ciblée `revue-42-condition-2` : PASS. G-1 rend `CONFORME` avec la citation. Sa contre-épreuve,
le même commit dépouillé de la citation dans une copie en /tmp, rend `HAUSSE-SANS-ARBITRAGE`, rc=1.

### Historique du point ouvert

Revue `revue-42-condition` (bdb1491..f257306) : gaps_found.
- **F5 / contournement.** L'ajout des interdits dépassait réellement la baseline de trois agents
  (vf-growth-manager 25/24, vf-design-manager 30/29, vf-design-judge 9/8, rejoué par le relecteur).
  Les commits 6ca1de8 et f257306 remplacent « interdits » par « garde-fous », que le compteur D-01 ne
  voit pas. Chez growth, « interdits » survit dans le bloc DIGEST fenced ; chez design, il a disparu.
  **Décision attendue :** (a) garder, ou (b) rétablir et monter la baseline de +1 sur ces trois
  fichiers, par un commit qui cite l'arbitrage (G-1). Recommandation du manager : (b).
- **À corriger après la décision** (nœud `fix-42-condition-2`, exécution de décisions déjà prises) :
  - F1 : doublon `CLAUDE.md` resté dans « Entrée » de vf-design-judge, contrairement à ce qu'affirme
    le SUMMARY ; T11 n'a pas l'assertion anti-doublon de ses trois suites sœurs.
  - F3 : CHANGELOG growth v2.0.12 et design v1.5.11 désynchronisés du contenu livré.
  - F4 : commentaire et message de T11 désynchronisés de l'assertion.
  - F2 : le message de 6ca1de8 attribue à tort un dépassement à growth-quality-judge ; à noter au SUMMARY.
- **Condition (b) de Samuel non remplie sur vf-dev-manager → vf-design-judge.** dev-orchestrator est de
  sa polarité et D-12 l'exclut de la 42. C'est écrit dans 42-05-SUMMARY.md, le BACKLOG et le STATE,
  et c'est à trancher à sa revue code owner.

## Plan de bataille (DAG, tel qu'exécuté)

1. `exec-42-w1` (42-01/02/03) → `exec-42-w2` (42-04) → `exec-42-w3a` (42-05 Tâche 1 + sonde du point de contrôle D-19).
2. Arrêt au point de contrôle (`ARBITRAGE-ABSENT`, rc=1), PR brouillon, reprise après consignation de l'arbitrage.
3. `exec-42-w3` (42-05 Tâche 3, I5/I6) → `exec-42-w4` (42-06 + `gsd-verifier`).
4. En parallèle : `revue-42` (vf-reviewer), `audit-42` (vf-auditer), `docs` (gsd-doc-verifier, lecture seule), `nonreg-42` (manager).
5. `arbitrage-juges-42` (humain) → `fix-42-juges` (correction ciblée) → `revue-42-fix` → `pr-42-ready`.

Hors de cette mission : `plan-43` / `check-43` / `pr-42` (PR empilée de la 43), comme le fixait le brief.

## Décisions (canal et date)

- **Arbitrage D-08 : maintenir.** Canal : session principale, décision déléguée par Willy au head
  (« tranche et avançons »), 2026-09-25. Samuel n'a PAS été consulté malgré la condition D-19 ; il peut
  rouvrir la décision. Consigné dans `42-D19-MESURE.md` § `## Arbitrage D-08` (commit 95a304d).
- **Seconde sonde D-19 (règles à `paths:`) :** décidée par Willy (AskUserQuestion, session principale,
  2026-09-24). Bloquée par l'authentification sous HOME temporaire, puis abandonnée le 2026-09-25 (head).
  Elle reste une question ouverte non bloquante : la doc officielle se contredit sur ce point. La
  première sonde tournait avec le HOME réel, limite consignée au même endroit.
- **Findings des juges finaux :** décision déléguée par Willy au head (« tranche et avançons »),
  session principale, 2026-09-25.
  - CR-01 (collision de nom masquant un orphelin I2/I3) : corrigé.
  - A1 (`.md` en lien symbolique lu hors arbre) : corrigé, refusé sans reflet.
  - A2 (collision de noms dans `.claude/scripts/` de l'installeur) : dette antérieure à la 42.
  - A3 (T-42-07 fausse pour deux juges) : corrigé, les deux corps citent le `CLAUDE.md` du lab
    (règles RGPD) comme source lue via Read ; revue de fond de leurs grilles en dette.
  - Spec fabrique : alignée sur le code.
  - WR-01 et WR-02 : corrigés (auto-fix).
- **Merge d'origin/main dans la branche (7f46365), pas de rebase** (manager, 2026-09-25). La branche
  était poussée et ses SHA cités dans le STATE, les SUMMARY et la mesure D-19. Le merge était sans
  conflit, et conductor est passé de v1.42.0 sur disque à v1.43.0 par 42-06.
- **42-06 tenue derrière D-08** jusqu'à l'arbitrage (manager, 2026-09-25) : même `check-agents.sh`
  que la Tâche 3 de 42-05, et la mineure de conductor doit décrire I5/I6.
- **Mémoires de vf-reviewer :** `project_phase42-corpus-ahead-of-invariant` et
  `feedback_defensive-fix-unreachable-via-real-cli` gardées. Le journal de revue `fix-42-juges`
  n'est pas gardé, puisqu'il redit git.

## Livré (13fcd27..HEAD, sans le contenu mergé de main)

- `plugin/conductor` v1.43.0 : manifeste daté `check-agents-manifest.json`, fraîcheur
  (`--manifest-freshness`), invariants I1 à I7, découverte récursive, détection des collisions
  d'identité, refus des `.md` symboliques, cible absente → INDÉTERMINÉ (D-20).
- Installeur : pose les `*.json` des modules (D-16).
- CI : `--manifest-freshness=strict` aux quatre appels de `check-agents`.
- Modules : mobile-test-team v1.4.6, business-pilot-bundle v2.0.12, content-bundle v2.0.12,
  growth-bundle v2.0.11, design-orchestrator v1.5.10. Aucun commit ne touche `dev-orchestrator`.
- Relecture de Samuel (D-12) : 0ab324b (mobile-test-team), f820f08 et b613e88 (design-orchestrator),
  4d69837 (`ci.yml`, CODEOWNERS).

## Gates rejoués (commandes canoniques)

| Gate | Commande | Sortie | rc |
|---|---|---|---|
| Suites (job tests) | `replay-ci-jobs.sh --job tests` | 89 suites, 2 échecs identiques à la base 13fcd27 : `test-register-codex-agent-path-traversal.sh` (T4 [majuscules], 15 ok/1 ko) et `test-check-description-fidelity.sh` (PyYAML absent, 8 OK/36 KO, rejouée seule) | 1 |
| Job gates | `replay-ci-jobs.sh --job gates` | 16 rejouées, 3 sautées (conditionnelles à main), 0 en échec | 0 |
| G-2 | `bash scripts/check-gate-touche.sh` | `marqueurs: lus=20 conformes=20`, `DECLARE` | 0 |
| G-1 | `bash scripts/check-baseline-arbitrage.sh` | `CONFORME` | 0 |
| STATE gouvernance | `check-state-integrity.sh --file .planning/workstreams/gouvernance/STATE.md` | conforme | 0 |
| Invariants de mission | `check-mission-invariants.sh` | SAIN | 3 |

Échec transitoire écarté : `test-check-description-fidelity.sh` T9 (fuite de répertoire temporaire) a
rougi une fois, pendant qu'un relecteur créait des fixtures en parallèle. Rejouée seule, la suite
revient à 8 OK / 36 KO, comme à la base.

## Dette ouverte (consignée au STATE gouvernance)

- Manifeste périmé le 2026-10-24 (`verifie_le` 2026-09-23 + 30 jours) : la CI stricte rougira sans rafraîchissement.
- A2 : collision de noms entre modules dans `.claude/scripts/` (installeur), antérieure à la 42.
- Revue de fond des grilles de quality-gate-client et content-clarity-judge (motif 3 de D-08).
- `requirements.mark-complete --ws gouvernance` résout vers le REQUIREMENTS.md de `fiabilite` (gsd-core 1.14.0) : contourné à la main.

## Coûts (décompte sur mandats émis et blocs reçus)

18 dispatches, un tour chacun. Jetons rendus par les notifications (17 sur 18) :

| Nœud | Agent | Jetons |
|---|---|---|
| exec-42-w1 | vf-coder | 367 859 |
| mesure de base CI | general-purpose | 92 991 |
| sonde-d19b | general-purpose | 77 631 |
| exec-42-w2 | vf-coder | 272 166 |
| exec-42-w3a | vf-coder | 251 204 |
| revue-42-partiel | vf-reviewer | non reçu (mission coupée par une erreur API) |
| exec-42-w3 | vf-coder | 370 697 |
| exec-42-w4 | vf-coder | 177 982 |
| revue-42 | vf-reviewer | 169 250 |
| audit-42 | vf-auditer | 195 783 |
| docs | gsd-doc-verifier | 37 304 |
| fix-42-juges | vf-coder | 272 482 |
| revue-42-fix | vf-reviewer | 131 058 |
| fix-42-condition-samuel | vf-coder | 244 991 |
| revue-42-condition | vf-reviewer | 169 259 |
| fix-42-condition-2 | vf-coder | 169 140 |
| revue-42-condition-2 | vf-reviewer | 119 304 |
| **Total connu** | | **3 119 101** |

`estimate` : absent de tous les plans. `actuals` relayés verbatim : 42-04 `tokens: 9353, tasks: 2, commits: 2` ;
42-05 (Tâche 1) `tokens: 5507, tasks: 1, commits: 1`. `verdicts` : aucun hook code_review/nyquist/secure rendu.

## Preuves E6

```json
{
  "preuves": [
    {"verdict": "nonreg:suites", "commande": "bash .planning/workstreams/fiabilite/phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job tests", "exit_code": 1, "sha": "17a07765aa38bc07ccf69366763967aa66cd917c"},
    {"verdict": "nonreg:description-fidelity-seule", "commande": "bash plugin/conductor/scripts/tests/test-check-description-fidelity.sh", "exit_code": 1, "sha": "df845bd152a2318d90dcf162903255e27757751c"},
    {"verdict": "gate:ci-gates", "commande": "bash .planning/workstreams/fiabilite/phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job gates", "exit_code": 0, "sha": "df845bd152a2318d90dcf162903255e27757751c"},
    {"verdict": "gate:G-2", "commande": "bash scripts/check-gate-touche.sh", "exit_code": 0, "sha": "df845bd152a2318d90dcf162903255e27757751c"},
    {"verdict": "gate:G-1", "commande": "bash scripts/check-baseline-arbitrage.sh", "exit_code": 0, "sha": "df845bd152a2318d90dcf162903255e27757751c"},
    {"verdict": "gate:state-integrity", "commande": "bash plugin/conductor/scripts/check-state-integrity.sh --file .planning/workstreams/gouvernance/STATE.md", "exit_code": 0, "sha": "df845bd152a2318d90dcf162903255e27757751c"},
    {"verdict": "checkpoint:D-19", "commande": "python3 -c <sonde verbatim de 42-05 Tâche 2> sur 42-D19-MESURE.md", "exit_code": 0, "sha": "95a304d"},
    {"verdict": "test-check-agents.sh", "commande": "bash plugin/conductor/scripts/tests/test-check-agents.sh", "exit_code": 0, "sha": "e3ba8f905301913ddbe8cb03af99a535f1e196d1"},
    {"verdict": "test-vibeflow-update.sh", "commande": "bash plugin/_internal/tests/test-vibeflow-update.sh", "exit_code": 0, "sha": "e3ba8f905301913ddbe8cb03af99a535f1e196d1"},
    {"verdict": "recette", "commande": "bash plugin/conductor/scripts/tests/test-check-agents.sh", "exit_code": 0, "sha": "6bb3cde0acda833aec553a80aeafbe08479a83e1"},
    {"verdict": "gate:G-2", "commande": "bash scripts/check-gate-touche.sh", "exit_code": 0, "sha": "6bb3cde0acda833aec553a80aeafbe08479a83e1"},
    {"verdict": "recette", "preuve": "amont"},
    {"verdict": "revue", "commande": "bash plugin/conductor/scripts/tests/test-check-agents.sh", "exit_code": 0, "sha": "e2ed4a160359424ea2b71840eee6a36c95626af6"},
    {"verdict": "revue", "preuve": "amont"},
    {"verdict": "audit", "commande": "bash scripts/check-gate-touche.sh", "exit_code": 0, "sha": "e2ed4a160359424ea2b71840eee6a36c95626af6"},
    {"verdict": "audit", "preuve": "amont"},
    {"verdict": "test-check-agents.sh", "commande": "bash plugin/conductor/scripts/tests/test-check-agents.sh", "exit_code": 0, "sha": "17a07765aa38bc07ccf69366763967aa66cd917c"},
    {"verdict": "test-guard-agent-write.sh", "commande": "bash plugin/conductor/scripts/tests/test-guard-agent-write.sh", "exit_code": 0, "sha": "17a07765aa38bc07ccf69366763967aa66cd917c"},
    {"verdict": "check-version-sync.sh", "commande": "bash scripts/check-version-sync.sh", "exit_code": 0, "sha": "17a07765aa38bc07ccf69366763967aa66cd917c"},
    {"verdict": "check-instruction-budget.sh", "commande": "bash plugin/conductor/scripts/check-instruction-budget.sh", "exit_code": 0, "sha": "17a07765aa38bc07ccf69366763967aa66cd917c"},
    {"verdict": "revue-fix", "commande": "bash plugin/conductor/scripts/check-agents.sh --agents-dir=<plugA/agents> --resolve-agents=strict --agent-registry-dir=<plugB/agents> (repro CR-01)", "exit_code": 1, "sha": "17a07765aa38bc07ccf69366763967aa66cd917c"},
    {"verdict": "gate:ci-gates", "commande": "bash .planning/workstreams/fiabilite/phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job gates", "exit_code": 0, "sha": "f2573062423c110fe11ffe37a6f27074a8bec193"},
    {"verdict": "test-growth-bundle.sh", "commande": "bash plugin/growth-bundle/scripts/tests/test-growth-bundle.sh", "exit_code": 0, "sha": "f2573062423c110fe11ffe37a6f27074a8bec193"},
    {"verdict": "test-design-orchestrator.sh", "commande": "bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh", "exit_code": 0, "sha": "f2573062423c110fe11ffe37a6f27074a8bec193"},
    {"verdict": "revue-condition", "commande": "check-instruction-budget.sh sur l'extraction du commit f0e3340 (design avant reformulation)", "exit_code": 3, "sha": "f0e334095128eab328f08d356807d8edbd4be5c8"},
    {"verdict": "gate:G-1", "commande": "bash scripts/check-baseline-arbitrage.sh", "exit_code": 0, "sha": "7dc6a29c93dd125e0105512e4d7d9a24d6feb4a6"},
    {"verdict": "gate:G-2", "commande": "bash scripts/check-gate-touche.sh", "exit_code": 0, "sha": "7dc6a29c93dd125e0105512e4d7d9a24d6feb4a6"},
    {"verdict": "gate:ci-gates", "commande": "bash .planning/workstreams/fiabilite/phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job gates", "exit_code": 0, "sha": "7dc6a29c93dd125e0105512e4d7d9a24d6feb4a6"},
    {"verdict": "gate:instruction-budget", "commande": "bash plugin/conductor/scripts/check-instruction-budget.sh", "exit_code": 0, "sha": "7dc6a29c93dd125e0105512e4d7d9a24d6feb4a6"},
    {"verdict": "revue-condition-2", "preuve": "amont"}
  ]
}
```

Les deux `exit_code: 1` des suites correspondent aux deux échecs déjà présents à la base 13fcd27 (même
ensemble, même détail). Celui de la repro CR-01 est le rouge attendu d'une collision.

## Prochaine étape

Relecture code owner de Samuel sur la PR #108 : `.github/workflows/ci.yml`, la hausse de baseline
(trois lignes), les modules de sa polarité et l'écart vf-dev-manager → vf-design-judge. Merge ensuite
par un humain. Puis le plan de la Phase 43 : rebase de `gouvernance/phase-43-cadrage` sur la 42 finale,
plan et plan-checker frais.
