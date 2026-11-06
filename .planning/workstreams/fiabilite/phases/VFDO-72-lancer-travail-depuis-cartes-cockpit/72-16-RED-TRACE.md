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

# Tâche 2 — module et processus : trace

Code : `vf-cockpit-lancer-mode.mjs` (57 lignes) ; `vf-cockpit-terminal-processus.mjs` : 199 → 203 lignes (un import, une création de mémoire `garde:mode-support`, `lireProposition` enrichie `garde:mode-servi`, un appel `ecrire` `garde:mode-ecrit` juste après le test de `w.ok` et avant `lq.confirmer`, une phrase d'en-tête). Contrat 72-CONTRATS.md §4 étendu (`mode_retenu`). Liste exacte de clés de Q2 de `test-cockpit-lancer-processus.sh` étendue (`mode_retenu`).

## Corrections du harnais découvertes au premier vert (aucune assertion affaiblie)

Premier rejeu de la suite du mode sur le code livré : 4 FAIL de harnais, tous corrigés avant le rejeu final.
- LM.S2 (témoin « le processus nomme le module ») comptait EXACTEMENT 1 ligne ; l'en-tête du processus en porte deux (le commentaire cite le module) : le témoin est devenu « au moins une ligne ». L'égalité d'ensemble des importeurs, elle, est inchangée.
- Trois mutants (M-ECRITURE-DIRECTE témoin Q6, M-ECRITURE-A-LA-DEMANDE, M-ECRITURE-AVANT-LE-SHELL) et la doublure « ecriture » de LM.Q6 jouaient une manche SANS session : `lancer()` rend alors 410 AVANT tout autre contrôle, le mutant n'était jamais atteint (obtenu `410 plan` au lieu de `404 acceptEdits`), et la doublure « 410, fichier inchangé » était verte pour la mauvaise raison. Ces manches ouvrent désormais le flux de l'onglet A (session vivante).

## Ensemble des FAIL attendu en fin de tâche 2 (W-2 : DÉRIVÉ de la trace rejouée, non recopié du plan)

Rejeu final au HEAD 2d54848e plus les fichiers de la tâche 2 : 66 PASS, 6 FAIL, aucun « mutant sans effet », aucune sonde « non jouée ».
`grep -o 'FAIL — [A-Za-z0-9.-]*' | sort -u` = { LM.C1, LM.C2, LM.C3, LM.S4, M-SERVI-NON-RELU, M-STOCKAGE-RESTE } = exactement l'ensemble du plan. Note sur LM.C2 : le plan prévoyait « vraisemblablement verte avant la tâche 3 » ; elle est ROUGE par construction, car son témoin positif (plan servi donne plan) est faux tant que le client lit son stockage : c'est voulu (un LM.C2 vert à vide, tous les cas « default », ne prouverait rien).
M-STOCKAGE-RESTE et M-SERVI-NON-RELU sortent en FAIL par leur précondition « sain/mutant » (le client livré n'est pas encore sain : `24/true/2/true/4` et `false/false`) : ce n'est PAS « mutant sans effet » (les ancres `garde:mode-lecture` et `garde:mode-relu` du client de la base existent et le mutant change bien la copie).

## Mutants rejoués sur le code livré (processus, module)

| Mutant | Sonde rougie | Obtenu sous le mutant |
|---|---|---|
| M-SANS-REVALIDATION | LM.U2 ; LM.Q5 | moins de 17 contenus forgés valent `default` ; `bypassPermissions` servi tel quel |
| M-SUIT-LIEN | LM.U3 ; LM.Q5 | lien symbolique lu : `plan` ; Q servie : `plan` |
| M-DROITS-IGNORES | LM.U3 | `plan,plan,plan,plan,plan` (0644, 0660, 0640 lus) |
| M-PROPRIETAIRE | LM.U3 | `plan,plan` (autre uid simulé lu) |
| M-TAILLE | LM.U2 | `plan,1,plan,1` (fstat 4096 déclenche une lecture) |
| M-BLOQUANT | LM.U3 (FIFO) | `TIMEOUT` (ouverture bloquée, échéance de 20 s) |
| M-ECRITURE-DIRECTE | LM.U4 ; LM.Q6 (témoin positif) | `true/false/false` (cible ouverte en écriture, ni temporaire ni rename) ; `acceptEdits meme-inode` |
| M-TEMPORAIRE-RESTE | LM.U4 | un `.tmp` reste après l'échec du rename |
| M-RELECTURE-A-CHAQUE-SONDAGE | LM.U5 | `plan,acceptEdits` |
| M-ECRITURE-A-LA-DEMANDE | LM.Q6 | `404 acceptEdits` (un id inconnu réécrit le fichier) |
| M-ECRITURE-AVANT-LE-SHELL | LM.Q6 | `410 acceptEdits` (le refus du shell laisse le fichier réécrit) ; sa doublure saine (même 410 sans le déplacement) : `410 inchange` |
| M-MODE-DANS-AUCUNE | LM.Q1 | clés `etat,mode_retenu` |
| M-NOUVELLE-ROUTE | LM.S3 | `/mode:POST` ajoutée à la table |
| M-MODE-VERS-P | LM.S5 ; LM.P3 | `1` ligne d'envoi portant le mode ; `lancee=non` (P refuse le message à clé de plus : forme fermée) |
| M-P-LIT-LE-FICHIER | LM.S2 ; LM.P1 | une référence à `terminal-mode` côté P ; la sentinelle est servie |
| M-SERVEUR-OUVRE-LE-CHEMIN | LM.G1 | chemin `terminal-mode` à la racine du lab, `check-ignore` rend 1 |

Écarts avec les rouges annoncés par le plan, dits : M-ECRITURE-DIRECTE rougit LM.U4 et le TÉMOIN POSITIF de LM.Q6 (inode inchangé), pas LM.Q3 (qui reste vert : le contenu est bien celui du dernier 204) ; M-NOUVELLE-ROUTE rougit LM.S3 seul (une route sans gestionnaire ne fait rien de plus que répondre 400, aucune écriture : rien à rougir dans LM.Q6) ; M-MODE-VERS-P rougit LM.P3 par le témoin positif « cible marquée lancée » (le message à clé de plus est refusé par P, il ne FUIT donc pas : `fuites=0` reste vrai), pas par une fuite.
Lignes finales : processus 203, module 57 (`check-file-size.sh` rc 0).
