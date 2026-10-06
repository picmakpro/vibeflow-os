---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 12
subsystem: planning-core
status: partial
requirements: [CLOT-10, CLOT-12]
tags: [reference, limites, v2.10.0, sans-release, P5, g4p-observation]
commit_list:
  - 3027b186 — P5 : .planning/surveillance.log ignoré à l'installation
  - 0811b4b8 — référence de la Phase 46 à l'état livré, v2.10.0 sans release
estimate:
  tokens: 150000
  raw_tokens: 150000
  tasks: 3
  confidence: low
actuals:
  tasks: 3
  note: "tâche 1 tranchée en amont ; tâche 2 non rejouée (voir ci-dessous) ; tâche 3 menée au bout ; tokens non mesurés"
verdicts:
  code_review: absent
  nyquist: absent
  secure: absent
key-files:
  modified:
    - plugin/planning-core/references/modele-cycles.md
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/VERSION
    - plugin/planning-core/module.json
    - plugin/planning-core/CHANGELOG.md
    - plugin/planning-core/README.md
    - plugin/_internal/vibeflow-update.sh
    - plugin/_internal/tests/test-vibeflow-update.sh
---

# Phase 46 Plan 12 : référence à l'état livré, planning-core v2.10.0 sans release, G4′ en observation

## Tâche 1 — porte de l'armement de l'étape 6

Réponse : `etape-6-mesure` — arbitrage Willy, AskUserQuestion session principale, 2026-10-06. G4′ reste en observation ; A2, A3, A4 et P1 sont reportés à une phase ultérieure, avant tout armement de G4′ (limite (bs)).

## Tâche 2 — rejeu réel de l'étape 6 : mesure faite (mesure seule)

Mesure jouée le 2026-10-06 après arrêt de la session active du lab BusinessFlow (arbitrage Willy, AskUserQuestion session principale, 2026-10-06 : « tu peux la fermer »), sous garde dure de repos : 0 processus dont le cwd est sous les deux labs, avant (19:01:58) et après (19:08:15). Relevé : `46-REJEU-ETAPE-6.md`, commit `f5280888`, sur HEAD `0f9db46e`.

Chiffres G4P : 96 cas (28 dans `~/jarvis-keystone`, 68 dans `~/BusinessFlow-Lab`), 24 agents, `COMPTE G4P faux-refus=0 faux-accept=0 refus-conforme-modele=0`, `COUVERTURE-REJEU G4P n=96 plancher=8`. Les 15 agents « producteur » avec Bash sont refusés sans sortie de commande brute et acceptés avec ; les autres passent dans les quatre cas. Empreintes des deux labs identiques avant/après.

Lecture par gate : le total `REJEU-ETAPE-6 faux-refus=349` mêle G4 (343, unités closes avant G4, limite (bp)) et G7 (6, attendus de la 45 non chargés, constat rendu, décision de Willy en cours) ; aucun faux refus ne vient de G4P. G1 compte 196 refus conformes au modèle.

Aucun armement : `ARMEMENT_G4P` vaut toujours `observe` (etape-6-mesure, arbitrage Willy, AskUserQuestion session principale, 2026-10-06 ; G4′ reste en observation). Le CHANGELOG et la référence disent encore « mesure de l'étape 6 : relevé à venir » : leur mise à jour avec les chiffres est hors de ce mandat et revient au manager.

## Tâche 3 — référence, limites, version, suites

- `modele-cycles.md` : état d'armement constaté (G6, G5, G1, G7, ROLE, G3 armés ; G4 et G4′ en observation ; table et § ordre déjà posés par `b703d73d`, cohérents, non retouchés), coût du pré-filtre par événement repris de `46-COUT-PREFILTRE.md`, « Hors de cette phase » réécrite.
- Limites : les lettres (bc) et (bd) du plan sont des lettres sautées de la référence et la plage va jusqu'à (bp) : posées sous les lettres libres suivantes, sans renuméroter. **(bq)** FileChanged sous `settings.json` non mesuré en 2.1.288 et #63148 sans objet ; **(br)** #60490 sans objet ; **(bs)** G4′ : A2, A3, A4, P1 reportés. `LIMITES_REFERENCE` de `test-planning-gates.sh` à jour (a) à (bs).
- Version : planning-core v2.10.0 (VERSION, module.json, README du module, CHANGELOG « Aucune release : le module reste en v2.10.0 (ADR-073) »). Aucun commit de la phase sur `VERSION` racine, `plugin.json`, `marketplace.json` ; aucun tag.
- **P5** (`3027b186`) : « L'ignorer » (arbitrage Willy, AskUserQuestion session principale, 2026-10-06). Lieu : `gitignore_add_paths()` de `plugin/_internal/vibeflow-update.sh`, scope local. Preuve : T3d de `test-vibeflow-update.sh` (contrôle neuf, deux négatifs, mutant tué). Limite : en scope project l'installation ne touche jamais au `.gitignore` (SCOPE-04), le journal n'y est pas ignoré.

### Rejeu des suites (bash, au premier plan, une à la fois, HEAD `0811b4b8` pour les suites planning-core ; `3027b186` pour la suite d'installation)

| Suite | Résultat |
|---|---|
| test-check-planning-state | 19 ok, 0 ko |
| test-cloture-empreintes | 49 OK · 0 KO |
| test-cloture-gates | 73 OK · 0 KO |
| test-d1-surveillance | 45 OK · 0 KO |
| test-detect-gsd-engine | 26 ok, 0 ko |
| test-detect-planning-debt | 10 passés, 0 échoués |
| test-g4p-sortie-brute | 19 OK · 0 KO |
| test-juges-canary | 14 OK · 0 KO |
| test-planning-context-hardening | 38 passés, 0 échoués |
| test-planning-core | 14 passés, 0 échoués |
| test-planning-gates | 497 OK · 0 KO |
| test-planning-hook-registered | 113 OK · 0 KO |
| test-planning-hooks | 42 PASS / 0 FAIL |
| test-planning-prefilter | table,bornes 6 OK ; corpus 5 OK ; evenements 5 OK ; section mutants non rejouée (CI) |
| test-recalc-planning | 409 OK · 0 KO |
| test-rejeu-gates | 100 OK · 0 KO |
| test-workstream-policy | 22 ok, 0 ko |
| test-workstream-symlink-escape | 10 ok, 0 ko |
| test-planning-hook-installed | 29 OK · 0 KO |
| test-vibeflow-update | 97 OK / 0 KO / 0 SKIP |
| test-hook-exit-parc | 42 OK / 0 KO |
| test-role-hook-vs-check-agents | 6 OK · 0 KO |

Contrôles : `check-version-sync.sh` vert ; `check-planning-consumers-registered.sh` vert ; `check-gate-touche.sh --base-ref 247194c7` rc 0 ; contrôle de marqueur de la phase `sans-marqueur=0` ; `check-machine-paths.sh` vert ; aucun tag.

## Reste hors de ce mandat

Relevé `46-REJEU-ETAPE-6.md` (mesure à rejouer, session inactive) ; clôture du jalon ; CI Linux (geste du manager à l'ouverture de la PR).
