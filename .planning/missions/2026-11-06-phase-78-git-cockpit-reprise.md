# Mission 2026-11-06 — Phase 78 « Git dans le cockpit », reprise après le crash

Le mandat est la reprise de la Phase 78. La machine a redémarré le 2026-11-05 à 21 h 58, et le manager `mgr78` est mort avec
ses trois codeurs. Samuel a décidé de reprendre à l'identique, par message direct en session principale le 2026-11-05 vers 23 h 20 :
« ok 1, mais non on reprend tel quel, ce qui a faire crash c'est que j'utilisais un jeu. Et d'autre session claude ».
Le brief d'origine et les messages relayés sont dans `.planning/archives/stash/2026-11-05-crash-mandat-78.md` (arbre principal).

- Branche : `feat/phase-78-git-cockpit`, worktree `.claude/worktrees/phase-78`, compartiment `fiabilite`.
- Verrou de phase repris par `takeover` (owner `mgr78-reprise`, génération `DRIVER.lock.gen.1793917142.5249`).
- Les trois enfants fantômes (exec-06, exec-08, exec-09) ont été fermés en `failed` au registre.
- Trailer `Fence` posé sur `93b90030`.

## Reprise : attribution du travail interrompu

- Le SUMMARY de 78-05 était déjà commité (`f08622aa`).
- `temoins/git-tiroir.json`, non suivi, venait de 78-06 : le codeur relancé l'a vérifié contre le schéma servi et l'a gardé.
- `test-cockpit-git-details.sh`, non suivi, venait de 78-08 : sa fixture était morte, le codeur relancé l'a corrigée avant le rouge.
- 78-09 : la Tâche 1 était commitée, la Tâche 2 restait à faire.

## Plan de bataille (DAG `MISSION-78.dag.json`, 19 nœuds, tous `done`)

- La vague 3 de reprise a joué exec-06, exec-08 et exec-09 en parallèle.
- exec-07 et exec-10 ont suivi en parallèle, puis exec-11.
- Correctifs ciblés : D-32/D-33, critique, audit, revue serveur, revue page, delta, puis mineurs.
- La critique design, l'audit et la revue ont été dispatchés dès que leur périmètre était figé, sans attendre exec-11.
- Recette par juge navigateur, puis docs, puis non-régression complète.

Écart assumé au DAG : la critique (après exec-10) et l'audit (après D-32) ont été lancés avant la fin d'exec-11, qui ne
touche aucun fichier d'UI ni de serveur.

## Décisions de la reprise (registre : `78-CONTEXT.md`)

Arbitrages de Samuel (AskUserQuestion, session principale, 2026-11-06) :
- P78-D-34 ratifiée : « Valider le seuil (Recommandé) » ;
- P78-D-36 : « Garder le plafond (Recommandé) » ;
- P78-D-37 : « Garder tel quel (Recommandé) » ;
- P78-D-39 : « Recherche à 152 px (Recommandé) », qui amende P70-D-16 de 1000 à 1279 px avec Git.

Décisions du manager, sur des zones grises techniques :
- P78-D-32 et D-41 : toutes les lectures des routes du tiroir sont asynchrones ;
- P78-D-33 et D-35 : texte neutre, application de la règle 71.5 ;
- P78-D-38 : un worktree au lien retour non vérifié n'est jamais lu ;
- P78-D-40 : libellé « Par branche — avance sur la base » ;
- P78-D-42 : dépôt sans branche de base ;
- P78-D-43 : la branche réelle est lue au chargement.

## Verdicts

- **Critique design** (`vf-design-judge`, regard frais) : 73/100, `gaps_found` sur 3 majeurs (nom du dépôt, pastille HEAD, seuil
  1000-1279 px). Les 3 majeurs et 9 mineurs objectifs sont corrigés (`c743e356`, `8edb0bf7`, `3db8c2e5`, `d8171e80`). F4, F7 et F11
  sont remontés à Samuel, F10 a été traité au même titre que G4 de la recette.
- **Audit sécurité en lecture** (`vf-auditer`) : 2 majeurs, des contournements de P78-D-21 (plafond de 64 filtres, filtres d'un
  sous-module), et 5 mineurs. Tous sont corrigés par classe (`d6eb8a13`, `b2dc3e0d`, `d0da89d0`, `0a8a9b63`). F8 et F10 sont `no-op` documentés.
- **Revue de code** (`vf-reviewer`, `8edb0bf7`) : 5 majeurs : dépôt sans base, signal écouté sur la mauvaise cible, mesure
  sur un chemin de poste, GITC-11, libellé « 30 jours ». Tous sont corrigés (`8c1857e1`…`4b6de753`, `ac3ebe3d`, `1d708d20`).
- **Revue de delta 1** (`a5ca8852`) : 1 majeur, « 0 commit » pour une avance inconnue. Corrigé (`d8171e80`).
- **Revue de delta 2** (`d8171e80`) : `passed`, 4 mineurs corrigés (`bb0349e6`, `ca0bbb09`).
- **Recette par juge navigateur** (`a5ca8852`) : R2, R3, R4, R5 et R6 `ok` ; R1 et R7 `partiel`. Les écarts, dont la branche
  périmée au chargement et les barres d'auteurs vertes, sont corrigés dans `d8171e80`, avec témoins mesurés et mutants.
- **Non-régression complète** (manager) : une régression trouvée, absente des rejeux ciblés des workers. Le tiroir Git nommait
  les classes du Terminal (`vf-term-*`), ce qui cassait T7.5 de la Phase 71. Corrigée sans couplage (`ae8ea226`).
- **Docs** (`gsd-doc-verifier`) : CHANGELOG et README corrigés (`47be7260`, `d8171e80`, `ca0bbb09`).

## Preuves E6

| Verdict | Commande | Code de sortie | SHA |
|---|---|---|---|
| gates | `replay-ci-jobs.sh --job gates` (40.1) : 21 rejouées, 4 sautées, 0 échec | 0 | à rejouer sur la tête finale, voir rapport |
| revue delta 2 | sondes `78-delta2-*` sur `git archive` | 0 | `d8171e80fa634051ce3cda37b4ecede3980ecdba` |
| audit | `bash plugin/cockpit/scripts/tests/test-cockpit-git-env.sh` | 0 | `97074369b6197bf6ace754a779a1d4fb9985ac08` |
| non-régression cockpit | boucle sur les 47 `plugin/cockpit/scripts/tests/test-*.sh` (journaux `78-nr2/`) : 46 à rc 0, `test-cockpit-terminal-activation.sh` T7.5 rouge | 1 | `ca0bbb09` |
| correction T7.5 | `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-activation.sh` (40/0), puis `test-cockpit-git-tiroir.sh`, `-terminal-tiroir.sh`, `-git-e2e.sh`, `-responsive.sh` | 0 | `ae8ea226` |

## Décompte

- 22 mandats émis : 15 `vf-coder`, 3 `vf-reviewer`, 1 `vf-design-judge`, 1 `vf-auditer`, 1 `gsd-doc-verifier`, 1 juge navigateur
  `general-purpose`.
- 4 reprises par SendMessage : un correcteur relancé deux fois, et deux élargissements de mandat.
- 3 escalades vers la session principale, toutes tranchées par Samuel.

## Limites

- `test-cockpit-securite.sh` FB3.5 : plafond d'horloge connu sous charge (78-05).
- Le titre de l'onglet du navigateur reste celui du dossier du lab dans un worktree (R6.1 conservé).
- Le parcours réel au lecteur d'écran et `pointer: coarse` ne sont pas joués.
- La Phase 71.5 n'est pas mergée : ses jetons (`--inset-panel`, `--edge`) remplaceront au rebase les valeurs de la grille posées
  ici (listées dans les SUMMARY 78-06 et 78-10).
- La Phase 72 reprend l'affichage Git et touche aussi `vf-cockpit-live.mjs` et `70-vf-live.js`, ce qui donnera des conflits au rebase.
