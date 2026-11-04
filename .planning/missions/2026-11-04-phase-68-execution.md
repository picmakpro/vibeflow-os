# Mission `mgr68` — exécution de la Phase 68 (vf-signal embarqué sur le socle partagé)

- **Date :** 2026-11-04
- **Manager :** vf-dev-manager, `mgr68`, verrou de phase `--ws=fiabilite --phase=68`. Fence `DRIVER.lock.gen.1793767079.96743`.
- **Branche :** `feat/phase-68-vf-signal`, worktree `.claude/worktrees/phase-68`, rebasée sur `origin/main` 794c6dba (Phase 69 mergée).
- **PR :** #199, en brouillon, sans release.
- **DAG :** `.planning/workstreams/fiabilite/MISSION-68.dag.json`.

## Plan de bataille

1. **`revalid-68`**
   - rebase (un conflit sur `REQUIREMENTS.md` : lignes CKPT de main gardées, lignes VFSG de la branche ajoutées) ;
   - plan-checker frais confronté à main (`plancheck-68e`) ;
   - révision des plans (`rev-68e`) ;
   - checker ciblé (`plancheck-68f`).
2. **Vagues d'exécution**, un vf-coder par plan, chacun dans son propre worktree `phase-68-wNN`, puis réintégration par rebase + fast-forward :
   - vague 1 : 68-01, 68-02, 68-04 ;
   - vague 2 : 68-03, 68-12 ;
   - vague 3 : 68-05 (68-09 était prévu en parallèle, bloqué par Q2) ;
   - vagues 4 à 6 : 68-06, 68-07, 68-08.
3. **Juges.**
   - Revue et audit du socle en parallèle de 68-05.
   - Revue du mod après 68-08.
   - Deux corrections ciblées en parallèle (`fix-socle`, `fix-mod`), puis une revue fraîche du diff de correction et une passe 2.
4. **Recette** par deux juges frais, chacun avec son propre Chromium headless (`playwright`) :
   - volet web et `claude -p` ;
   - volet TUI, en pseudo-terminal rejoué dans xterm.js.
5. **PR brouillon** ouverte tôt pour avoir le verdict de la CI Linux.

## Décisions du manager (consignées dans `68-CONTEXT.md` ; aucune n'est un arbitrage de Samuel)

- **P68-D-27** : verrou de phase périmé + compartiment tenu → `abandonnee`. Témoin V9.8.
- **P68-D-28** : option `pluginRoot` retirée de `driverLockScript`. Le conductor voisin de la 69 tient P68-D-13.
- **P68-D-29** : les suites s'isolent du conductor voisin par un dossier de scripts explicite.
- **P68-D-30** : le jalon affiché dans l'en-tête est celui de la phase active, lu dans `signal@1`.
- **Plans scindés** : 68-04 en 68-04 + 68-12, 68-09 en 68-09 + 68-13 (recommandations du plan-checker).

## Plans

| Plan | État | Preuve principale |
|---|---|---|
| 68-01 | fait | `test-cockpit-vie.sh` (V0 à V14, mutants) |
| 68-02 | fait | `test-cockpit-retard.sh`, 38/0 |
| 68-03 | fait | `test-cockpit-signal.sh`, 72/0 après corrections |
| 68-04 | fait | `claude plugin validate --strict`, I9 rouge sur l'engine muté |
| 68-12 | fait | gating E1 à E4, M6 |
| 68-05 | fait | K1 à K17, 11 mutants |
| 68-06 | fait | `disk.ts` supprimé, R6, J1 |
| 68-07 | fait | Q1 à Q3, A1 à A3, M8 |
| 68-08 | fait | R8-G1 à G5b, M9, M10 |
| 68-09 | partiel | partie 2 (compte des suites) faite, `cd8653f6` ; tâche 1 et parties 1 et 3 bloquées par Q2 |
| 68-13 | bloqué | dépend de 68-09 |
| 68-10 | bloqué | dépend de la recette (tri) et de 68-13 |
| 68-11 | bloqué | dépend de Q1 |

**Corrections de revue.**
- Socle : F-02 à F-08, puis RV-4, RV-5 et RV-7.
- Mod : ST-1, ST-3 à ST-7, puis RV-1 (majeur : `complet()` rejetait le signal réel d'un lab plat), RV-2 et RV-3.

Chaque correction a son témoin rouge puis vert, dans `68-FIX-SOCLE-RED-TRACE.md` et `68-FIX-MOD-RED-TRACE.md`.

## En attente de Samuel (escaladé à la session principale par SendMessage)

- **Q1.** Périmètre de 68-11 : bump racine (P68-D-08) ou bump du module seul, la release étant groupée.
- **Q2.** Porte de légitimité du paquet `@anthropic-ai/claude-code` (68-09, tâche 1). Porte humaine, jamais automatique.
- **Q3 (F-01, revue du socle).** La cascade de vie ignore le verrou de dépôt. Une mission vivante sous `acquire` sans `--ws` s'affiche « abandonnée ».
- **Q4 (ST-2, revue du mod).** Le lanceur du bouton « Ouvrir le cockpit » et le repli `driver-lock.sh` de l'élagage sont pris sous `<lab>/.claude/scripts/`, ce qui contredit T-67-06.
- **Tri de recette R1 à R15** : cinq gênants, huit cosmétiques, deux pour Samuel seul (retrait de l'ancien mod ; VS Code et mobile, injouables par un juge).

## Recette par juges

- **Volet web et CLI.** Étapes 8, 9 et 12 conformes. Étapes 7 et 11 en écart.
  - Preuves : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/`.
- **Volet TUI.** Étapes 1, 2 (thème clair) et 3 conformes. Étapes 2 (sombre), 6 et 10 en écart. Étapes 4 et 5 injouables par un juge.
  - Preuves : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/`.
- Le croisement des identifiants `who@2` / `$.agent.list()` est constaté sur un agent réel.

## Constats hors périmètre (consignés, non corrigés)

- **`scripts/check-machine-paths.sh` rejoué sous macOS rend un vert à vide.**
  - L'univers balayé est le même (2488 fichiers), mais le gate n'a vu aucune des quatre lignes `/home/<user>` et `/Users/<user>` du cadrage et des patterns. La CI Linux de la PR #199 les a vues.
  - Cause probable : un lot `xargs` sur lequel l'`awk` de macOS échoue, l'erreur étant avalée par `2>/dev/null`. Non sondé plus avant.
  - Conséquence : les verts « check-machine-paths » rapportés par les workers sous macOS ne valent rien. Seule la CI Linux fait foi.
- **L'audit sécurité (`vf-auditer`) s'est figé deux fois**, sans rendre de verdict (transcripts immobiles 30 à 60 min). La couverture sécurité repose sur deux revues avec sondes, dont un reviewer qui a sondé l'injection, fsmonitor, T-67-06, les caractères de contrôle et la borne de durée.
- **`test-cockpit-robustesse.sh`** porte encore des faux verrous de forme `scope:"repo"`, qu'aucune version réelle de `driver-lock.sh` n'émet (l. 82 et 116).

## Preuves E6

Verdicts des blocs typés des vf-coder, relayés tels quels :

- **68-01**
  - `bash plugin/cockpit/scripts/tests/test-cockpit-vie.sh` : rouge 5/25 avant le code, vert 30/0 (`34bf26f3`).
  - `test-cockpit-projet.sh` : vert 61/61 (`5c9b290a`).
- **68-02** : `bash plugin/cockpit/scripts/tests/test-cockpit-retard.sh` : rouge 8/30 (`f27cc32a`), vert 38/0 (`3be2d265`).
- **68-03** : `bash plugin/cockpit/scripts/tests/test-cockpit-signal.sh` : rouge 10/33 (`7ce542e2`), vert 43/0 (`32400bfc`).
- **68-04** : `claude plugin validate --strict plugin` rc=0 ; `claude plugin test plugin` 3 pass ; suite statique 17 ok.
- **68-12** : `claude plugin test plugin` : E1 rouge, puis vert, 8 pass / 0 fail (`d0d8e3ef`).
- **68-05** : `claude plugin test plugin` 24 pass / 0 fail.
- **68-06** : rouge 23/10 (`c815fd3c`), vert 35/0 (`46182014`).
- **68-07** : rouge 35/16 (`6030ebf4`), vert 54/0 (`d73de532`).
- **68-08** : rouge (`7d9af482`), vert 63/0 (`d9a45336`).
- **fix-mod**
  - Passe 1 : 95 pass, `17686e83`.
  - Passe 2 : 103 pass, `e680b7cd`, rebasé en `cde56d40`.
- **fix-socle**
  - Passe 1 : signal 70, vie 50, who 91, `df3380c7`.
  - Passe 2 : signal 72, vie 52, `072bcb86`.
- **68-09, partie 2** : `bash scripts/check-version-sync.sh` : rc=1, puis rc=0 (`cd8653f6`). Job `gates` rejoué par `replay-ci-jobs.sh --job gates` : 20 étapes, 0 échec.

## Décompte de mission

- Mandats émis : 2 plan-checkers, 1 réviseur de plans, 10 exécuteurs de plan (dont 68-09 partie 2), 4 passes de correction (2 correcteurs, 2 tours chacun), 3 revues, 2 audits (figés), 2 juges de recette.
- Merges sur `main`, release : aucun.
