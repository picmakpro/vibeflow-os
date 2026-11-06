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

# Tâche 3 — rouge de la suite bandeau transposée, jouée sur le client de la base (avant tout code client)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-bandeau.sh` au HEAD 3fa5a965 (client inchangé, 280 lignes) : 63 PASS / 6 FAIL, aucune erreur de harnais, aucune « SUITE SAUTÉE » (Chrome présent), aucun « mutant sans effet ».

| Sonde | Attendu | Obtenu sur le client de la base | Raison du rouge |
|---|---|---|---|
| LB.C4 (présélection servie) | `sain` (douze valeurs servies : absent, forgées, valides) | `rouge` | le client lit son stockage, la valeur servie est ignorée |
| LB.C4 (aucune clé `mode` du stockage) | `sain` | `rouge` | le client lit et écrit `vf.terminal.mode` (opérations get/set observées) |
| LB.E2 | `…/204/0/null` | `…/204/0/acceptEdits` | la clé `vf.terminal.mode` du stockage de Q est encore écrite au 204 |
| LB.E5 | `SecurityError/secret/acceptEdits/default` | `SecurityError/secret/acceptEdits/acceptEdits` | la valeur forgée servie (bypassPermissions) est ignorée, le client relit une valeur périmée de son stockage ; le témoin SecurityError et le témoin du secret sont VERTS |
| LB.E6 | `plan/0` | `acceptEdits/0` | la présélection ne vient pas du serveur factice (plan) mais du stockage laissé par E2 |
| M-MODE-NON-RELU (volet Chrome) | `SecurityError/secret/acceptEdits/bypassPermissions` | `SecurityError/secret/default/default` | le client de la base n'a pas le chemin « valeur servie » que le mutant doit casser (précondition : le témoin acceptEdits servi n'est pas rendu) |

Vertes déjà sur la base, avec leur raison : LB.E7, LB.E2 (partie « aucun octet à /entree » et armement), LB.F1 à LB.F3, LB.C1 à LB.C3, LB.C5 à LB.C7, LB.S1 à LB.S4 (pas de changement de la forme), M-PARAM-URL (volet Chrome : le paramètre d'adresse du mutant est lu avant toute autre source, donc visible même sur la base ; sa sonde statique LB.S1 est, elle, la sonde décisive).
Précision sur LB.E2 : le plan 72-16 le disait « intact » ; sa dernière valeur lisait la clé `vf.terminal.mode` (le mode lancé) : elle ne peut plus tenir. Transposée (voir le tableau final) : la clé reste ABSENTE (`null`), plus fort qu'avant.

# Tâche 3 — vert, mutants du client et tableau de transposition

Code : `vf-cockpit-terminal-client.mjs` 280 -> 279 lignes (plafond LB.S3 : 280, jamais relevé ; aucun module neuf nécessaire). `CLE_MODE` retiré, `modeRetenu()` remplacée par `modeServi(p)` (marqueurs `garde:mode-lecture` et `garde:mode-relu` CONSERVÉS pour que les mutants existants visent les lignes), `modeInitial` posé par `lire` depuis le JSON brut, `setItem` du 204 retiré ; `forme(j)` n'exige pas `mode_retenu`. `grep -c vf.terminal.mode` du client : 0.

## Deux corrections du harnais au premier vert de la suite bandeau (aucune assertion affaiblie)

- LB.E1 : le serveur factice servait `acceptEdits` par défaut (consigne du plan) ; la commande affichée de E1 est celle du mode présélectionné, donc l'attendu « ligne default » rougissait (`false/1/true/true/true`). Le défaut du serveur factice est `default` (premier lancement) ; LB.E5 sert `acceptEdits` EXPLICITEMENT pour son témoin. Aucun attendu modifié.
- M-MODE-NON-RELU, volet Chrome (LB.E5) : retiré. Le menu déroulant normalise une valeur hors liste vers `default` : la présélection forgée non relue est invisible dans le DOM, E5 ne peut donc pas rougir sous ce mutant (obtenu `…/acceptEdits/default`, identique au sain). C'est exactement le constat de W-1 (« au HEAD il rougit LB.C4, pas E5 ») : le mutant vise LB.C4, sonde qui existe encore, et ses indices (`j.lu[1]`, `j.lu[9]`) sont inchangés parce que la liste des douze valeurs l'est.

## Rejeu au vert

`test-cockpit-lancer-bandeau.sh` : 68 PASS / 0 FAIL (Chrome présent : aucune « SUITE SAUTÉE », aucun « mutant sans effet »). `test-cockpit-lancer-mode.sh` : 72 PASS / 0 FAIL, aucune « non jouée », dont les six sondes rouges de la fin de tâche 2 (LM.S4, LM.C1, LM.C2, LM.C3, M-STOCKAGE-RESTE, M-SERVI-NON-RELU), désormais vertes.

## Mutants rejoués sur le code livré (client, bandeau transposé)

| Mutant | Sonde rougie | Obtenu sous le mutant |
|---|---|---|
| M-STOCKAGE-RESTE | LM.S4 ; LM.C3 | 1 occurrence de `vf.terminal.mode` ; `1/true` (un `getItem` d'une clé mode) ; précondition « sain » : `0/true` sur le client livré |
| M-SERVI-NON-RELU | LM.C2 | `false` (bypassPermissions devient la présélection) ; précondition `true` sur le client livré |
| M-MODE-NON-RELU (existant, repointé) | LB.C4 | `bypassPermissions=>bypassPermissions` à l'indice 1 (verdict `rouge`) ; les valeurs valides restent lues (indice 9) |
| M-PARAM-URL (existant, réécrit sur la nouvelle ligne `const v = new URLSearchParams(location.search).get('mode') \|\| p.mode_retenu;`) | LB.S1 (statique) ; LB.E6 (Chrome) | `URLSearchParams` lu ; `acceptEdits/0` au lieu de `plan/0` |

## Tableau de transposition (ancien attendu -> nouvel attendu -> verdict)

| Sonde | Avant | Après | Pourquoi ce n'est pas plus faible |
|---|---|---|---|
| LB.C4 (1) | douze valeurs LUES du stockage (clé `vf.terminal.mode`) : `absent=>default \| bypassPermissions=>default \| … \| herite=>herite` | LA MÊME liste de douze valeurs, SERVIE par `mode_retenu` : même chaîne attendue, mot pour mot | même entrée forgée (douze valeurs), même sortie ; le canal change, la relecture contre la liste fermée reste testée sur chacune ; mutant M-MODE-NON-RELU conservé |
| LB.C4 (2) | « après 204 la clé vaut le mode lancé ; inchangée après 409, 425, 400, 500 ; un seul `setItem` » | « AUCUNE opération (get, set, del) sur une clé dont le nom contient `mode`, après 204, 409, 425, 400, 500 ; secret lu (témoin) ; le bandeau suivant le 204 présélectionne le mode servi (`plan`), inchangé (`acceptEdits` servi) après chaque échec » | zéro opération au lieu d'une ; observation prouvée sensible (le secret, lui, est vu, et M-STOCKAGE-RESTE rougit) ; la propriété « le mode n'est retenu qu'au 204 » passe à Q, prouvée par LM.Q6 (neuf refus) et ses mutants |
| LB.E2 (dernier champ) | `acceptEdits` (clé du stockage = mode lancé) | `null` (clé du stockage absente après le 204) | la clé reste absente : plus fort ; le plan le disait « intact », ce qui était faux (le champ lisait la clé retirée) |
| LB.E5 | `SecurityError/acceptEdits/default` : SecurityError, témoin « le stockage de Q porte le mode », forgée dans le stockage -> `default` | `SecurityError/secret/acceptEdits/default` : SecurityError, témoin « le stockage de Q porte le SECRET » (W-3 : la clé du mode n'existe plus), serveur factice servant `acceptEdits` -> présélection `acceptEdits` (témoin positif), servant `bypassPermissions` -> `default` | un champ de plus (le témoin du secret) ; la sonde SecurityError est inchangée ; le témoin positif de la présélection est conservé ; limite dite : le menu normalise une valeur hors liste, E5 seul ne prouve pas la relecture (LB.C4 et M-MODE-NON-RELU la prouvent) |
| LB.E6 | adresse `?mode=acceptEdits…`, stockage vidé : `default/0` | adresse identique, serveur factice servant `plan` : `plan/0` | un paramètre d'adresse lu donnerait `acceptEdits` : la sonde DISCRIMINE désormais (l'ancienne valeur `default` ne distinguait le paramètre que parce que le stockage était vide) ; M-PARAM-URL rougit LB.E6 en Chrome et LB.S1 |
| LB.E7, LB.E2 (autres champs) | intacts | intacts | aucune lecture du stockage |

Les ancres `garde:mode-lecture` / `garde:mode-relu` : même nom, nouveau texte de ligne (`const v = p.mode_retenu; // garde:mode-lecture` ; `return MODES.indexOf(v) >= 0 ? v : 'default'; // garde:mode-relu`) ; le texte de la table des gardes de `72-08-PLAN.md` n'est PAS modifié (plan exécuté).
Hors `files_modified`, dits : `test-cockpit-lancer-bout-en-bout.sh` (CH2 parle d'un premier lancement : le mode retenu par les manches B survit désormais aux relances ; le fichier est retiré avant la section CH, un `rm -f` et un commentaire) ; `72-16-PLAN.md` (phrase de l'INFO ajoutée à T-72-128).
