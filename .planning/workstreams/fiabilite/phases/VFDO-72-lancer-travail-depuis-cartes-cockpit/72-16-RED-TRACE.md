# 72-16 — trace du rouge (tâche 1)

Date : 2026-11-06. Base : HEAD 2b9e23b9 (branche feat/phase-72-lancer-depuis-cartes), module `vf-cockpit-lancer-mode.mjs` ABSENT, processus et client de Q non modifiés.
Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh > red.log 2>&1` — sortie : 16 PASS, 26 FAIL (dont la garde anti-vert-à-vide, 42 assertions jouées < 55), 23 sondes « non jouée : module absent » dites, exit 1.

## Rouges, pour la bonne raison

| Sonde | Attendu | Obtenu sur la base | Raison du rouge |
|---|---|---|---|
| LM.S1 | `terminal-mode/default,acceptEdits,plan,herite` | `absent` | module absent |
| LM.S4 | `0/true/true` | `4/true/true` | le client contient encore `vf.terminal.mode` / `CLE_MODE` (stockage encore présent) |
| LM.U1 à LM.U6 (13 libellés) | faits du module | `plante: module absent` | module absent (import impossible, signalé tel quel, jamais un faux vert) |
| LM.C1 | `default=>default,acceptEdits=>acceptEdits,plan=>plan,herite=>herite` | `default=>default,acceptEdits=>default,plan=>default,herite=>default` | la valeur servie est ignorée (le client lit son stockage) |
| LM.C2 | `true` | `false` | le témoin positif (plan servi donne plan) échoue : valeur servie ignorée |
| LM.C3 | `0/true` | `24/true` | le client lit/écrit encore une clé `mode` du stockage (24 opérations) ; le secret est bien lu (l'observation fonctionne) |
| LM.Q1 (mode_retenu) | `en-attente/default` | `en-attente/undefined` | clé `mode_retenu` absente de la proposition |
| LM.Q2 | clés du contrat + `mode_retenu` | clés du contrat sans `mode_retenu` | clé absente |
| LM.Q3 (écriture) | `204 plan/600` | `204 ` | aucun fichier posé : Q n'écrit rien |
| LM.Q3 (survie) | `autre-port plan` | `autre-port undefined` | port différent (témoin de la prémisse VERT), clé `mode_retenu` absente |
| LM.Q4 | `204 autre-port acceptEdits 0` | `204 autre-port undefined 0` | clé absente (le dernier 204 n'est écrit nulle part) |
| LM.Q5 | `default ×5 acceptEdits` | `undefined ×6` | clé absente (témoin positif acceptEdits compris) |
| LM.Q6 (témoin positif) | `204 acceptEdits/600 inode-change` | `204 plan/600 meme-inode` | un lancement accepté ne touche pas le fichier posé (« plan », même inode) |
| LM.Q7 | `ok 204 409 acceptEdits` | `ko 14/15 204 409 plan` | clé absente dans 14 réponses sur 15 ; le fichier reste `plan` |
| LM.Q8 | `herite 425 flux-inchange / 204 TROUVE claude-absent` | `undefined 425 flux-inchange / 204 TROUVE claude-absent` | présélection `herite` non servie (armement, 425 et absence de retour chariot : déjà verts) |

## Vertes sur la base, et pourquoi

| Sonde | Pourquoi elle est déjà verte |
|---|---|
| LM.Q0, LM.P0 | témoins positifs : parent, Q prête, amorçage, invite ; P répond, cibles 200 |
| LM.Q1 (réponse `aucune` à la seule clé `etat`) | la base ne sert aucun mode : vrai à vide, ne prend sens qu'avec M-MODE-DANS-AUCUNE |
| LM.Q6 (refus avant armement 425, id inconnu 404, mode hors liste, champ ligne, secret, Origin, onglet, chat, GET répétés, 409 au premier plan, `POST /annuler`) | AUCUNE écriture n'existe sur la base : « fichier inchangé » est vrai par construction ; ces refus ne prouvent quelque chose qu'après la tâche 2, par M-ECRITURE-A-LA-DEMANDE et M-ECRITURE-AVANT-LE-SHELL. Le témoin positif de la même sonde, lui, est rouge |
| LM.Q9 | le message `lancee` de la base ne porte pas le mode ; prend sens avec M-MODE-VERS-P |
| LM.C4 | le corps de `POST /lancer` est déjà `{ id, mode }` : vert, doit le rester |
| LM.G1, LM.G2, LM.G3 | la sortie du build porte son `.gitignore` `*`, le build ne purge pas `.cache`, `serve.mjs` ne purge que `skill.json` et `history` : propriétés de la base, tenues |
| LM.P1, LM.P2, LM.P4 | le fichier (sentinelle) existe mais aucun code ne le sert ni ne l'écrit : vert à vide, ne prouve quelque chose qu'après la tâche 2 par M-P-LIT-LE-FICHIER |
| LM.P3 | témoin positif (cible marquée lancée : le message est arrivé à P) vert, fuites 0 |
| H0 | hygiène : aucun processus de la suite ne survit |

## Non jouées sur la base (dites, jamais comptées)

LM.S2, LM.S3, LM.S5/LM.S6, LM.G1 (chemin du processus), la doublure `ecriture` de LM.Q6 et les dix-huit mutants M-* : « non jouée : module absent ». Un mutant dont l'ancre manque une fois le module posé sort sous le libellé distinct « mutant sans effet » (FAIL), jamais confondu avec un rouge attendu.

## Mutation du harnais pendant la tâche

Le lab de la suite portait d'abord `- [x] Phase 1` (phase finie : bloquant `phase-finie`, la cible n'est jamais proposée) : LM.P3 rendait `lancee=non` pour une mauvaise raison (harnais). Corrigé en `- [ ] Phase 1` AVANT le rouge tracé ; LM.P3 est alors vert (`lancee=oui fuites=0`).
