# Phase 45 — Discussion log

**Date :** 2026-09-29
**Manager :** `vf-dev-manager-g45-20260929`
**Canal :** Willy, AskUserQuestion session principale, 2026-09-29. Les questions ont été relayées
par la session principale (repli D-09 : pas d'outil de question en sous-agent). Après le `/clear`
de la session principale, Willy a reconfirmé tel quel : « Willy, AskUserQuestion session
principale, 2026-09-29 (reconfirmation après /clear) ».

## Déroulé

1. Deux recherches en lecture seule, parallèles (nœud `recherche-hooks`) :
   - doc des hooks Claude Code 2.1.284 (ADR-045) ;
   - cartographie du dépôt.

   Les faits sont reportés dans `45-SCOUTING.md`.
2. Six questions de zone grise posées à Willy, avec les faits, les options et une recommandation
   séparée. Treize décisions sont proposées en « délégué ».
3. Réponses de Willy : Q1 (a), Q2 (a) avec une précision, Q3 (b), Q4 (a), Q5 (a), Q6 (a). Les
   décisions déléguées sont validées en bloc.
4. `/clear` de la session principale pendant l'attente. Le contexte du manager est perdu, pas les
   faits : les rapports et les réponses ont été retrouvés dans la transcription de la session. Le
   manager a demandé une **reconfirmation** au lieu de tenir un relais relu pour une validation.
   Willy a reconfirmé tel quel.

## Questions, options, choix

| # | Question | Options | Choix |
|---|---|---|---|
| Q1 | `phases_trace: false` / `gates: false` (renvoi P44-D-05) | (a) sans effet, armement par l'adhésion, désarmement par dérogation nominative seule · (b) un drapeau de `config.json` désarme, les refus deviennent des avertissements · (c) `phases_trace: false` éteint G1/G2, protections G5-G7 armées | **(a)** |
| Q2 | Lab métier qui contient du code (détecteur 2 → refus en 44) | (a) l'adhésion explicite l'emporte, seul GSD actif (0) refuse · (b) seconde déclaration nominative « contient du code, reste métier » · (c) refus maintenu, code dans un lab emboîté | **(a)**, avec un test de régression : sans adhésion, refus de la 44 inchangé |
| Q3 | Ordre d'armement | (a) tous ensemble après canary et mesure · (b) par étapes G6+G5 → G1 → G7 → rôle, G2 avertit dès le départ · (c) mode observation d'abord sur un lab réel | **(b)** : canary et faux refus en CI, puis rejeu en lecture seule sur Keystone et BusinessFlow |
| Q4 | Portée du hook par rôle | (a) labs métier adhérents seuls · (b) tous les labs, worker = hors allowlist refusé · (c) table de la spec telle quelle partout | **(a)** |
| Q5 | Source du rôle | (a) dérivé du frontmatter par I5/I6, worker = `vf-internal` · (b) champ `vf-role:` déclaré, dérive détectée · (c) table centrale par lab | **(a)** |
| Q6 | Hook ou `python3` absent | (a) bloquer, la commande enregistrée émet le refus et un message de réparation · (b) laisser passer, canary au démarrage et en CI | **(a)** |

## Décisions déléguées validées

Les 13 décisions déléguées deviennent P45-D-07 à P45-D-19 dans `45-CONTEXT.md` :
- commande de verdict, et G5 sur toute écriture par outil ;
- deny JSON avec exit 0 ;
- matcher `Agent|Task` ;
- Bash non couvert, G2 avertit ;
- fil principal ou agent inconnu : ligne « Tous » seule ;
- racine du lab tirée du chemin ;
- dérogation nominative, journal protégé par G6 ;
- G7 fail-closed ;
- un seul script dans planning-core ;
- CI Linux ;
- préfixe `GATE` ;
- bump mineur, sans release ;
- `guard-planning-updated.sh` conservé.

## Décisions du manager (après la reconfirmation, non relues par Willy)

- **P45-D-01a** : le périmètre de tous les gates est le lab adhérent. C'est la conséquence de Q1
  (a) et Q4 (a).
- **P45-D-03a** : l'état d'armement vit dans le code livré, jamais dans le lab (spec §5.2,
  règle 1).
- **P45-D-03b** : seuil d'armement à 0 faux refus et 0 faux accept. Un compte non nul remonte à
  Willy.
- **P45-D-05a, P45-D-05b** : contrôle croisé du rôle avec `check-agents.sh`, et ordre de
  résolution des définitions.
- **P45-D-06a** : le fail-closed est limité au lab adhérent, et l'adhésion est décidée sans
  `python3`. Sans cette limite, Q6 (a) contredirait Q4 (a) sur un lab dev sans `python3`.
  C'est le risque technique principal de la phase.
- **P45-D-20, P45-D-21** : mécanisme du canary et protocole du rejeu en lecture seule.
