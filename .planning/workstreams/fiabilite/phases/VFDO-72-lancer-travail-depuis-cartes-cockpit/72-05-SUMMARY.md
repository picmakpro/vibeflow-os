---
phase: 72
plan: 05
status: complete
requirements: [LANC-04, LANC-07, LANC-10]
commits: [0f550702, a36293ba, 84c24e50, 9b37b072, 592ce39b]
---

# 72-05 — état de Q du lancement

Trace du rouge et des mutants : `72-05-RED-TRACE.md` (rouge joué sur le module absent, commit `0f550702` ; dix-neuf mutants rejoués sur le code livré, tous tués).

## Commits

- `0f550702` test : suite `test-cockpit-lancer-q.sh` (LQ1 à LQ7, dix-neuf mutants), rouge joué (1 PASS d'hygiène / 68 FAIL, `ABSENT`)
- `a36293ba` docs : trace du rouge
- `84c24e50` test : LQ7.3 constate l'existence du module (le contrôle de taille rend 0 sur un fichier absent), chemin corrigé, motif des noms de compartiment assemblé à l'exécution
- `9b37b072` feat : `plugin/cockpit/scripts/vf-cockpit-lancer-q.mjs` (140 lignes)
- `592ce39b` docs : trace des mutants

Le plan prévoyait l'ordre test, docs, feat, docs : un commit de correction de la suite (`84c24e50`) s'intercale, pour une raison tracée dans la RED-TRACE (rouge LQ7.3 pour une mauvaise raison).

## Valeurs retenues

- `ARME_MS` = 1000 : délai de protection d'entrée, compté depuis le PREMIER `lire()` qui rend la proposition (jamais la création). Ordre de grandeur marqué [ASSUMED] dans l'en-tête du module (non mesuré).
- `EXPIRE_MS` = 120000 : le temps d'ouvrir le tiroir, lire les pré-vols, choisir un mode. Réglage de test : `VF_COCKPIT_LANCER_ARME_MS` (100 à 10000), `VF_COCKPIT_LANCER_EXPIRE_MS` (1000 à 600000) ; hors bornes ou non entier : défaut ; expiration <= armement : les deux défauts.

## Motif -> statut HTTP livré à 72-10

`inconnue`, `consommee`, `annulee`, `remplacee`, `expiree`, `absente` -> 404 ; `mode`, `chat` -> 400 ; `pas-arme` -> 425 ; `bloquee`, `occupee` -> 409. Côté `proposer` (message IPC, pas de statut HTTP) : `liste-absente`, `forme`, `absente`, `compose`. `definirCibles` : `{ ok:false, motif:'liste' }` ou `{ ok:true, retenues, ecartees }`.

## Gabarit attendu (noms de référence de 72-01)

`lignesParModes({ session, verbe, phase, ws, chat }) -> { ok:true, lignes:{ default, acceptEdits, plan, herite }, intention, nom } | { ok:false, motif }`, `validerLigne(ligne) -> { ok }`, `MODES`, `VERBES`. Sans `chat`, la clé `chat` est ABSENTE de l'argument (première invocation) ; avec un chat, une seconde invocation avec `chat`, même `session`. 72-10 passe l'export réel du gabarit : `creerEtatLancer({ gabarit })`.

## Clés ajoutées à `lire()` (à relayer par 72-10)

Avec un `chat` UUID valide dans la proposition, `lire()` ajoute `chat: true` (booléen, jamais l'identifiant) et `lignes_chat` (quatre clés) ; sans chat, exactement les onze clés du contrat §4. `consommer(id, mode, chat)` : `chat` booléen strict (absent ou `false` = ligne standard, `true` = `lignes_chat[mode]`), tout autre type = refus `chat`, `true` sans `lignes_chat` = refus `chat`.

## Points d'audit

- Consommation en DEUX temps (`consommer` réserve, `confirmer` acte et rend `{ t:'lancee', cible, verbe, session, at }`, `rendre` restitue la proposition, même id, même session, même `vue_a`, tant qu'elle n'a ni expiré ni été remplacée). Une écriture refusée n'est pas un usage.
- Extension chat additive (72-13, contrat §9) : retirable par le manager sans toucher au reste.
- Écart mineur au plan, sans effet sur ses critères : `lignes_chat?.[mode]` (chaînage optionnel) sur la ligne `garde:chat-ligne`, pour que M-CHAT-SANS-LIGNES rougisse par une valeur (`ok` au lieu de `chat`) et non par une exception.
- `bloquants` et `avertissements` sont exigés comme tableaux dans le message de P (fail closed) : un message de P qui les omettrait est refusé `forme`.
- `phase` et `ws` d'une entrée de liste ne sont pas validés par ce module (le contrat les confie au gabarit) : un refus du gabarit devient `compose`.
- Mesuré : `check-file-size.sh` rend exit 0 sur un fichier absent ; toute suite qui s'appuie sur lui doit constater l'existence à part.

## Non-régression

Suite neuve : `test-cockpit-lancer-q.sh`, 69 PASS / 0 FAIL sous bash et sous zsh. Aucun fichier existant modifié : aucune suite existante n'exerce le module neuf ; `test-cockpit-projet.sh` (P4.7 `node --check`, P4.8 noms de compartiment) et `test-cockpit-assemblage.sh` rejouées (voir le rapport du mandat).
