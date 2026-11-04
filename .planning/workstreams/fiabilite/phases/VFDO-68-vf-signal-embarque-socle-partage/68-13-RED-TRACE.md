# 68-13 — trace rouge : runs CI réels sur la PR #199 (VFSG-08, P68-D-07)

PR #199 (brouillon) ouverte par le manager sur consigne de mission (session principale Claude Code, 2026-11-04) : le checkpoint « Samuel ouvre la PR » est levé à ce titre.

RUN_ROUGE=41857935466
RUN_VERT=41859018567

- Run rouge : https://github.com/picmakpro/vibeflow-os/actions/runs/41857935466 (SHA `a9948a7462144208f1c6b23995c1f8058a5acefd`, commit `test(68-13): témoin rouge CI — test du mod cassé exprès (à retirer)`, casse E1 `embarque.test.tsx:83` `toBe(0)` -> `toBe(1)`).
- Run vert : https://github.com/picmakpro/vibeflow-os/actions/runs/41859018567 (SHA `eb89e98f7492b66a2086c5472fcc404750294527`, commit `revert`, arbre identique à `0d4f8ae0`).
- Image du runner (job `gates`, les deux runs) : `ubuntu-26.04`.
- Local avant push n°1 : `claude plugin test plugin` rc=1, un seul `(fail)` : E1. Avant push n°2 : rc=0, 153 pass / 0 fail.
- Note : le run `41857935466` a été marqué `cancelled` au niveau du run (annulation par concurrence au push n°2, shards encore en cours) ; le verdict du job `gates` était déjà `completed/failure` et se lit par `gh run view --json jobs`.

## Run rouge — job « Gates de qualité (mode strict) » (étapes non sautées : numéro | nom | conclusion)

    - 1 | Set up job | success
    - 2 | Run actions/checkout@v4 | success
    - 3 | check-agents --strict sur chaque plugin/*/agents (découverte non vide) | success
    - 4 | check-agents --strict sur chaque plugin/*/AGENT.md (module mono-agent) | success
    - 5 | check-agents --resolve-agents=strict (monde fermé — union de tous les plugin/*/agents) | success
    - 6 | check-skills (classe d'invocation des skills — POCK-07, étape propre) | success
    - 7 | check-blueprints (le frontmatter cible passe le gate qu'il vise) | success
    - 8 | check-version-sync (canon VERSION ↔ plugin.json ↔ marketplace ↔ badges ↔ triade par module) | success
    - 9 | check-state-integrity (anti-régression du frontmatter .planning/STATE.md, ADR-063) | success
    - 10 | check-capability-activation (une entrée de doc ne promet pas un geste inerte, GSDA-09) | success
    - 11 | check-machine-paths (aucun chemin absolu de machine dans les fichiers versionnés) | success
    - 12 | check-python-isolation (aucune invocation inline de Python non isolée — hotfix H-1) | success
    - 13 | check-instruction-budget (BUDG-01/02/04/05, ADR-029 machine-enforced) | success
    - 14 | Gates workstream-aware sur un arbre RÉELLEMENT partitionné (fixture jetable) + non-régression racine | success
    - 15 | check-divergence.sh en CI (C17, 2026-09-10) — mutation rouge sur fixture divergente, pas seulement présence du gate | success
    - 16 | check-planning-consumers-registered (D-03 — un consommateur de chemin de planning oublié est VU) | success
    - 17 | check-baseline-arbitrage (G-1, PROT-04 — hausse de baseline sans arbitrage cité) | success
    - 18 | check-gate-touche (G-2, PROT-05 — la PR modifie ce qui la juge) | success
    - 19 | check-ajout-retrait (SOBR-05, consultatif — un ajout à la méthode dit ce qu'il retire) | success
    - 20 | check-affirmation-non-mesuree (G-4 — affirmation de prose non mesurée) | success
    - 21 | check-manual (cohérence du manuel utilisateur FR+EN — manual/.tools/check-manual.sh) | success
    - 22 | check-push-sans-pr (G-3 — preuve par fixture, sans condition) | success
    - 24 | Run actions/setup-node@v4 | success
    - 25 | Mod vf-signal du module cockpit — claude plugin validate --strict et claude plugin test (VFSG-08) | failure
    - 52 | Post Run actions/checkout@v4 | success
    - 53 | Complete job | success

Log de l'étape 25 : témoin intégré (copie) `152 pass / 2 fail`, `rc=1` attendu non nul, puis arbre réel `152 pass / 1 fail`, `(fail) E1 — sans ligne cockpit=…`, `Process completed with exit code 1`. Aucune étape antérieure à 25 en `failure`.

## Run vert — même job

    - 1 | Set up job | success
    - 2 | Run actions/checkout@v4 | success
    - 3 | check-agents --strict sur chaque plugin/*/agents (découverte non vide) | success
    - 4 | check-agents --strict sur chaque plugin/*/AGENT.md (module mono-agent) | success
    - 5 | check-agents --resolve-agents=strict (monde fermé — union de tous les plugin/*/agents) | success
    - 6 | check-skills (classe d'invocation des skills — POCK-07, étape propre) | success
    - 7 | check-blueprints (le frontmatter cible passe le gate qu'il vise) | success
    - 8 | check-version-sync (canon VERSION ↔ plugin.json ↔ marketplace ↔ badges ↔ triade par module) | success
    - 9 | check-state-integrity (anti-régression du frontmatter .planning/STATE.md, ADR-063) | success
    - 10 | check-capability-activation (une entrée de doc ne promet pas un geste inerte, GSDA-09) | success
    - 11 | check-machine-paths (aucun chemin absolu de machine dans les fichiers versionnés) | success
    - 12 | check-python-isolation (aucune invocation inline de Python non isolée — hotfix H-1) | success
    - 13 | check-instruction-budget (BUDG-01/02/04/05, ADR-029 machine-enforced) | success
    - 14 | Gates workstream-aware sur un arbre RÉELLEMENT partitionné (fixture jetable) + non-régression racine | success
    - 15 | check-divergence.sh en CI (C17, 2026-09-10) — mutation rouge sur fixture divergente, pas seulement présence du gate | success
    - 16 | check-planning-consumers-registered (D-03 — un consommateur de chemin de planning oublié est VU) | success
    - 17 | check-baseline-arbitrage (G-1, PROT-04 — hausse de baseline sans arbitrage cité) | success
    - 18 | check-gate-touche (G-2, PROT-05 — la PR modifie ce qui la juge) | success
    - 19 | check-ajout-retrait (SOBR-05, consultatif — un ajout à la méthode dit ce qu'il retire) | success
    - 20 | check-affirmation-non-mesuree (G-4 — affirmation de prose non mesurée) | success
    - 21 | check-manual (cohérence du manuel utilisateur FR+EN — manual/.tools/check-manual.sh) | success
    - 22 | check-push-sans-pr (G-3 — preuve par fixture, sans condition) | success
    - 24 | Run actions/setup-node@v4 | success
    - 25 | Mod vf-signal du module cockpit — claude plugin validate --strict et claude plugin test (VFSG-08) | success
    - 51 | Post Run actions/setup-node@v4 | success
    - 52 | Post Run actions/checkout@v4 | success
    - 53 | Complete job | success

Log de l'étape 25 : `== témoin rouge : claude plugin test sort rc=1 sur la copie au test cassé (attendu non nul) ==`, puis arbre réel `153 pass / 0 fail`, `Ran 153 tests across 14 files`.

## Sonde Linux (reportée par 68-09)

Jouée par ces deux runs sous `ubuntu-26.04`, `@anthropic-ai/claude-code@2.1.318`, `HOME` vide : `validate --strict` passe, `test` rouge/vert comme attendu.

## Durée ajoutée au job `gates` (T-68-27)

Job `gates` : 56 s (run rouge, 15:28:37 -> 15:29:33) et 62 s (run vert, 15:35:33 -> 15:36:35). L'étape du mod seule : environ 40 s (installation npm, validate, deux exécutions de `test`).
