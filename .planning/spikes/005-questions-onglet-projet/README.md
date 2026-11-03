---
spike: 005
idea: cockpit-code-projet
name: questions-onglet-projet
type: comparison
validates: "Given le cockpit 002 servi par floorplan/serve.mjs, when on pose une question en français dans la barre de l'onglet Projet, then la réponse s'affiche dans le tableau natif de floorplan (cartes cliquables, ids valides du graphe Projet), immédiate pour les questions courantes et argumentée pour les autres"
verdict: VALIDATED
related: [002-cockpit-code-projet, 003-cockpit-floorplan-live]
tags: [cockpit, floorplan, questions, llm, claude-cli, planning]
---

# Spike 005 : poser des questions à l'onglet Projet

## Ce qu'on valide

Limite laissée par le spike 002 : `serve.mjs` ne répond qu'au graphe de code. La barre de question
était même masquée sur l'onglet Projet. Given le cockpit servi, when on demande « qu'est-ce qui
reste dans la phase 61 ? » ou « pourquoi COLB-08 n'est-elle pas cochée ? », then la réponse
s'affiche dans le tableau de réponse natif de floorplan, avec des cartes du graphe Projet.

## Recherche : comment floorplan répond

- `serve.mjs` lit `graph.json` et le cœur de `query.mjs`. Chaque question lance `claude -p` en
  lecture seule (Read, Grep, Glob, et Bash limité à `node floorplan/query.mjs`), avec un schéma
  JSON imposé : `{ title, answer, items, steps, followups }`. Le viewer dessine les `items` en
  tableau et rend les `[[id]]` cliquables.
- Le viewer active la barre seulement si `window.FLOORPLAN_SERVER` est injecté. `serve.mjs` ne
  l'injecte que dans `/` ; `/project.html` était servi comme un fichier brut.
- La requête `/api/ask` ne dit pas de quel onglet elle vient (corps : `question`, `mode`,
  `session`). Le jeton, lui, est lu dans la page.
- `createGraphQuery` est générique (nœuds, fichiers, liens) : il marche tel quel sur le graphe
  Projet, mais ses résumés n'ont ni statut ni pied de carte.

| Approche | Pour | Contre | Statut |
|---|---|---|---|
| A. Agent (`claude -p`) sur le graphe Projet | répond à tout, va lire les PLAN/SUMMARY | 24 à 30 s, tokens du compte | **retenue en second** |
| B. Réponses calculées (formes courantes) | 2 à 6 ms, 0 token, déterministe | ne sait pas raisonner | **retenue en premier** |
| Patcher le viewer pour envoyer l'onglet | explicite | un patch de plus dans 175 Ko de viewer | écartée : le jeton suffit |

**Choix** : B d'abord, A pour le reste. L'onglet est identifié par un **second jeton**, injecté
dans `project.html` : aucun patch du viewer.

## Lancer

```bash
node .planning/spikes/002-cockpit-code-projet/build-cockpit.mjs <root>   # copie vf-ask.mjs, vf-query.mjs
node <root>/floorplan/serve.mjs --no-open [--model sonnet]
# ouvrir http://127.0.0.1:4378/project.html et poser une question dans la barre du bas
node .planning/spikes/005-questions-onglet-projet/probe.mjs [--llm]       # sonde, serveur lancé
node <root>/floorplan/vf-query.mjs ask "Où en est-on ?"                   # voie locale seule
```

## Ce qui a été construit

- **Patch P7** sur `serve.mjs` (7 marqueurs `vibeflow P7`, consigné dans `VENDORED.txt`) :
  - charge `vf-ask.mjs` s'il est présent, sert `project.html` avec un jeton propre (`ptoken`) ;
  - `/api/ask` avec ce jeton : `answerLocally()` d'abord, sinon l'agent avec les instructions
    Projet et le droit d'appeler `node floorplan/vf-query.mjs` ;
  - relit `project.html` quand le direct (spike 003) le réécrit.
- `vf-ask.mjs` (108 l.) : `extract`, `answerLocally` et le prompt Projet en français.
  - Formes reconnues : où en est-on, bloqué, en cours, ce qui reste (jalon, phase, mission),
    exigences d'une phase, une exigence par son ID, qui a touché un fichier, une carte nommée.
  - Les questions de raisonnement (pourquoi, comment, risque, conseil…) partent toujours à
    l'agent.
- `vf-query.mjs` (61 l.) : la CLI de l'agent sur le graphe Projet (`overview`, `find`, `show`,
  `status <st> [--in <id>]`, `path`, `ask`). Les résultats portent `st` et `foot`.
- `00-vibeflow.js` : la barre n'est plus masquée sur l'onglet Projet quand le serveur la sert.
- `probe.mjs` : batterie de questions par `/api/ask` avec le jeton lu dans la page. Mesure la
  voie, le délai et la validité des ids cités ; vérifie qu'un faux jeton est refusé et que
  l'onglet Code ne prend jamais la voie locale.

## Ce qu'on observe (2026-11-01, dépôt réel, Claude Code 2.1.316, `--model sonnet`)

| Question | Voie | Délai | Cartes | Ids invalides |
|---|---|---|---|---|
| Où en est-on ? | locale | 6 ms | 6 | 0 |
| Qu'est-ce qui bloque ? | locale | 2 ms | 4 (mission 414) | 0 |
| Qu'est-ce qui reste dans la phase 61 ? | locale | 3 ms | 3 (COLB-08, COLB-09) | 0 |
| Quelles exigences pour la phase 61 ? | locale | 3 ms | 9 | 0 |
| COLB-08 | locale | 3 ms | 2 | 0 |
| Qui a touché `plugin/conductor/scripts/driver-lock.sh` ? | locale | 4 ms | 8 plans | 0 |
| Mission 59 | locale | 2 ms | 14 | 0 |
| Phase 999 | locale (introuvable) | 3 ms | 0 | 0 |
| Pourquoi la phase 62 a choisi l'option A ? | agent | 24,0 s | 4 | 0 |
| Phases d'ecc-inspiration qui dépendent du verrou, et ordre ? | agent | 29,6 s | 9 | 0 |

- Faux jeton : 403. Jeton de l'onglet Code : jamais de réponse locale.
- L'agent a lu `62-DECISION-plateforme.md` de lui-même. À la seconde question, il a répondu
  « aucune dépendance dans la carte » et nommé ce qu'il n'avait pas vérifié. Il n'a pas inventé
  de lien.
- Navigateur (Playwright) : la barre s'affiche sur l'onglet Projet (« Claude Code · sonnet »).
  La réponse locale ouvre le tableau natif avec ses cartes reliées
  (`captures/1-reponse-locale.png`). « Pourquoi COLB-08 n'est-elle pas cochée alors que la
  phase 61 est faite ? » rend en environ 15 s une réponse juste, avec 5 cartes : COLB-08, la
  phase 61, les plans 61-08 et 61-05, la release v2.74.0. Elle cite le SUMMARY de clôture
  (`captures/2-reponse-agent.png`).
- `project.html` réécrit (comme le fait le direct) : la nouvelle page est servie 820 ms après.

## Trace de l'investigation

1. **Barre invisible** : `window.FLOORPLAN_SERVER` était bien injecté, mais `#ask` restait en
   `display: none`. En cause, une règle du spike 002 (`00-vibeflow.js`) qui masquait la barre sur
   l'onglet Projet. → Masquée seulement sans serveur.
2. **Réponse locale qui oublie l'essentiel** : « ce qui reste dans la phase 61 » rendait « 0 à
   finir ». Les 8 plans sont faits, mais 2 exigences restent ouvertes. → Pour une phase, les
   exigences ouvertes comptent dans « ce qui reste ».
3. **Fausse assurance** : « Pourquoi la phase 62 a choisi l'option A ? » était capté par la forme
   « carte nommée » et recevait le résumé de la phase. La réponse avait l'air juste mais ne
   répondait pas. → Toute question de raisonnement part à l'agent. C'est le défaut principal d'une
   voie locale : mieux vaut répondre moins que répondre à côté.
4. **Intégration avec 003** : `serve.mjs` garde la page en mémoire et ne surveille que
   `index.html`. Sans correctif, un rechargement après un événement `structural` resservirait
   l'ancien `project.html`. → `watchFile` sur `project.html` (P7), vérifié à 820 ms.
5. **Mode « flow » cassé par construction** (relecture du patch) : la table des modes Projet ne
   contenait que `ask`, donc un parcours demandé depuis l'onglet Projet serait parti avec le schéma
   de réponse au lieu du schéma de parcours. → La table Projet hérite des modes de code et ne
   remplace que `ask`.
6. **Témoin d'onglet** : la question témoin de l'onglet Code est coupée à 2 s, pour ne pas payer
   une réponse d'agent sur le graphe de code ; elle prouve seulement l'absence de voie locale.

## Résultats

**VALIDATED** : l'onglet Projet se questionne dans le tableau natif de floorplan, sans patch du
viewer. Il faut un patch serveur (P7), deux modules VibeFlow et une ligne d'extension.
- Les questions de suivi courantes sont **instantanées et gratuites** (2 à 6 ms, 0 token, ids
  toujours valides).
- Les questions de raisonnement passent par l'agent : 15 à 30 s, et des réponses sourcées dans
  `.planning/`.

Limites et suites :
- **Chrome en anglais** : « Answer », « On this board », « Back to map », « Ask anything
  about… », et la progression de l'agent (« Searching the map », « Looking at »). C'est le sujet
  du spike 006.
- **Les « en cours » du graphe gardent les zombies** : la mission 18 est donnée « en cours ».
  Il faut croiser avec le collecteur du spike 004 (TTL, âge du dernier commit) pour marquer les
  nœuds périmés dans les réponses.
- **Formes reconnues par regex** : couverture à étendre par l'usage (« qu'est-ce qui a été livré
  cette semaine », releases, backlog, graines). Chaque forme ajoutée doit garder la règle « une
  question de raisonnement part à l'agent ».
- **Suite de conversation** : une question de suite avec `session` va toujours à l'agent, la
  voie locale ne garde pas de contexte.
- **Coût de la voie agent** : celui du compte connecté. `--model sonnet` donne 15 à 30 s ; sans
  `--model`, c'est le modèle par défaut de Claude Code.
- **Mode « flow »** (parcours guidés demandés depuis la carte) : non adapté à l'onglet Projet, il
  reste branché sur les instructions de code.
