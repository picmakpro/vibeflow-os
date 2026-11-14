# Mission — exécution de la Phase 76, « Traçabilité au cockpit » (2026-11-13 → 2026-11-14)

Manager `vf-dev-manager`, mode autonome, régime allégé (consigne de Samuel, message session principale, 2026-11-13,
appliquée par la session principale). Demande : Samuel, session principale, 2026-11-11. Verrou `--ws=fiabilite --phase=76`.
Branches : `feat/phase-76-tracabilite` (76-01 à 76-07, PR #244 fusionnée, PR #246 dans le lot de fusion), puis
`feat/phase-76-questions` (76-09, 76-08, clôture ; PR ouverte à la clôture vers `fusion/lot-242-246-248-238`).

## Livré (plan, sha du code)

- 76-01 chaîne d'exigences `328a5afe` · 76-02 décisions, `vf-cockpit-registres.mjs` (partagé avec la 73) `3153d517`
- 76-03 mémoire des agents `ab5e5822` · 76-04 branchement dans la collecte `3c587121` (transmis à la 75 et à la 77)
- 76-05 route `GET /api/vf/tracabilite` `2a1f3923`, constat haut d'audit H-1 corrigé `16057a84`
- 76-06 page : phase, preuves, Jalon, exigence `1e2bed01` · 76-07 Décisions et Mémoire `366d0080`
- 76-09 questions en attente (C76-Q2, `meta.vf.questions`) `9e370a1b` · 76-08 retrait du nœud Exigences `5de90fab`
- Correctifs : revue 1 (archives en double) `438a2ef6` ; revue finale M1 et M2 `2e2875b2`, `9a61faea` ; juge de design
  (défilement horizontal, Jalon, pliage) `f270a216`, `5be44b57`, `2d14d781` ; UI-SPEC, huit mineurs `d526cc38`. TRAC-01 à 13 cochées, AUDC-I33 livré, ROADMAP 9/9.

## Écarts

- Rituels levés (mutants hors plan d'audit, triple passe, rejeu complet avant et après de 76-08) : une ligne par SUMMARY.
- 76-08 : le négatif strict passe au mot entier `\bcouvre\b` (« recouvre » dans un commentaire de la 80), avec témoin
  positif ; décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée, 2026-11-14.
- 76-09 : forme C76-Q2 augmentée sans rupture (`etat: 'mal-formee'`, `ws` sur les entrées complètes).
- 76-06/07 : bornes de hauteur prises dans l'UI-SPEC amendée, pas dans les plans.

## Rouges de CI rencontrés et cause

- PC3.2 (`test-cockpit-projet-champs.sh`) : liste fermée sans les champs de 76-04 → `79f452ef`.
- E0.2, D8.9, compteur des README : ajouts de 76-05 → `a9483467`, `c0ba62a0`.
- `test-cockpit-magasin.sh` : `rtk` en dur (79, cueilli `3cc622df`) puis C2, abonné `planning` de la 76 → `9d6bb8ac`.
- N5.1 (`test-cockpit-reconnexion.sh`) : rouge aussi sur la #242 ; cause dans la suite de la 79, corrigée par `6d79241d`.
- F7.4a (frise, 79) cueilli `736933ae` ; W24.4 (who, 73) et C5/MUT-3 (`test-ci-shard-suites.sh`, durées des
  suites des phases 73 à 80 absentes de la table) : hors périmètre, décision de la session principale.

- Après la fusion du lot : cliquet des observateurs abaissé (77-vf-git-tiroir.js, 80-11) `ccbcc0b7` ; attente du rendu des sondes de panneaux portée à 30 s sous charge `4caf666e`. CI de la PR de clôture : en cours à l'écriture.

## Mineurs versés au BACKLOG

Cinq sections datées : points de fusion 1 et 2, revue finale et vérification, juge de design, poids P76-Q-03 (+1,29 Mo)
et limite de rafraîchissement de la clé `planning` (écrite aussi dans `plugin/cockpit/README.md`).

## Ce qu'une autre phase doit savoir

- 73 : `definitionsRegistre(txt, { phase, ws, fichier, couper })` ; C76-Q2 servi par le graphe Projet et sa route.
- 77 : `construireGraphe` finit par `projeterTrace(…)` ; compteurs de mémoire sous `memoire.compteurs` de la route.
- 79 : une vue abonnée au magasin change le compte à froid de son onglet (C2 de `test-cockpit-magasin.sh`).
- 80 : sa porte `lireExigences` lit `meta.vf.trace.exigences` ; clés `meta.kindLabels` du nœud Exigences retirées ;
  l'en-tête de la feuille à 390 px laisse voir le texte qui défile dessous.
- Historique : un chemin du poste est resté dans `33dd061f` (retiré de l'arbre par `04088f5a`) ; purge à décider par Samuel.

## Preuves E6

```json
{"preuves":[
 {"verdict":"ci-pr-246-verte","commande":"CI GitHub Actions de la PR #246 (76-06, 76-07), run relancé","exit_code":0,"sha":"bd53c8c6"},
 {"verdict":"check-version-sync","commande":"bash scripts/check-version-sync.sh","exit_code":0,"sha":"4caf666e"},
 {"verdict":"check-machine-paths","commande":"bash scripts/check-machine-paths.sh","exit_code":0,"sha":"4caf666e"},
 {"verdict":"check-gate-touche","commande":"bash scripts/check-gate-touche.sh --root <wt> --base-ref origin/fusion/lot-242-246-248-238 (RIEN-A-JUGER)","exit_code":3,"sha":"4caf666e"}
]}
```
