# 75-05 — Trace des rouges : route et schéma de l'activité

Base du rouge : `bba9aecd` (75-01 à 75-04, 79-13, 79-15 livrés). Régime allégé, exception de sécurité tenue : chaque garde porte un témoin rouge puis vert ET un mutant vu rouge
(`MUTANT-ROUGE — <nom>` dans la sortie de `test-cockpit-activite-route.sh`). Chemins relatifs à la racine du dépôt.

## Tâche 1 — une ligne de table, la réponse gardée, un objet minimal

Étape 0, forme livrée relevée : `ROUTES` de `plugin/cockpit/scripts/vf-cockpit-server.mjs` (lignes `[chemin, lecteur, régime?]`), lecteur `(ctx, req, url)`, réponse gardée
`repondreGardee` appelée par `creerRepartiteur` (`vf-cockpit-routes.mjs`) ; `ctx` porte `root` et `here`.

| Témoin | Base (module absent) | Attendu | Obtenu | Raison |
|---|---|---|---|---|
| R1 | `GET /api/vf/activite` | `200` et les neuf champs | `404`, corps illisible | la route n'existe pas (aucune ligne de table) ; le serveur est bien lancé (R0 vert) |

Vert après : module minimal, une ligne de table, bloc de schéma. `R1` à `R4` verts.

`test-cockpit-routes.sh` (R3a) : après l'ajout de la ligne de `ROUTES` et AVANT la mise à jour de la liste écrite à la main :
`RK.1` rouge (la liste de RK.1 ne contient pas `/api/vf/activite`), `RK.7` rouge (le compteur attendait 9 routes, la table en compte 10 ; les sondes d'accès
de la route elle-même, dérivées de `ROUTES`, n'ont rien relevé), `M-LITTERAL`, `M-HISTORIQUE-NEUF`, `M-ORDRE` rouges par ricochet (leurs verdicts partent de RK.1) :
`51 PASS / 5 FAIL`. Après l'ajout de `/api/vf/activite` à la liste (sa place alphabétique, en tête) et du compteur `10|10` : `56 PASS / 0 FAIL`.

Mutants de la tâche (rouges, chacun pour sa raison) :

| Mutant | Témoin | Raison du rouge |
|---|---|---|
| `ligne-en-double` | R3 | la table compte deux lignes `/api/vf/activite` |
| `ligne-hors-ordre` | R3 | la ligne passe derrière `doing` : l'ordre n'est plus alphabétique |
| `controle-recopie-dans-le-module` | R2 | `x-vf-cockpit-token` apparaît dans le module |
| `bloc-sans-interdits` | R4 | `interdits` du bloc vide : la liste n'est plus recopiée |

Hors fichiers du plan (écart, dit au rapport) : `test-cockpit-lecture-fil.sh` D8.9 et D8.9b listent par égalité les schémas dont les `interdits` portent `fil` ; le bloc neuf
en fait un huitième (`cockpit-activite@1`), les deux chaînes attendues le portent désormais (même geste que 79-13 pour `cockpit-frise@1`). Rejoué : 17 PASS.

## Tâche 2 — assemblage des cinq sections, cache par clé, mono-vol, une requête pendant le calcul répond

Base du rouge : `758c33b3` (module minimal : objet vide mais conforme, `en-calcul` à vie). Suite rejouée en `TOUT=1` (tout rejouer, sans s'arrêter au premier FAIL) sur une copie du
module à cet état : `10 PASS / 15 FAIL`, durée 333 s (chaque témoin attend 25 s un `calcul: pret` qui ne vient jamais).

| Témoin | Attendu | Obtenu sur la base | Raison |
|---|---|---|---|
| R5 | `ok,pret,ok,ok,ok,ok` et les sections lues | `en-calcul,en-cours,en-lecture,en-lecture,en-lecture,en-construction` | rien n'est calculé : aucune section |
| R5b | cinq collisions de quatre sources, noms, tuple de plan | `###` (aucune) | idem |
| R13 | sources `agents,arbres,branches,plans` | aucune source | la fusion n'existe pas |
| R14 | `1,true,false` | aucune marque, aucun compte | idem |
| R6 | `0,1,1,` (zéro invocation, un seul `log` à la clé changée) | `0,0,,` | le zéro est vrai parce qu'aucun calcul ne part ; le `log` attendu (un) manque ; c'est le mutant `signature-relue-par-requete` qui établit que le zéro peut rougir |
| R7 | un seul `log`, objet précédent servi | `0` `log` ; `en-cours,en-calcul,en-lecture,true` | aucun calcul : pas d'objet précédent |
| R12 | zéro commande interdite, arbre intact | le cas lève (lecture de `git.fenetre`) | pas de section git |
| R9 | `200\|json\|true,true,true\|OK` | `200\|json\|false,false,false\|OK` | la réponse ne porte ni `doing`, ni `messages`, ni `fil` : rien n'est servi |
| R10 | `absent,absent,non-lues,ok,pret,ok` | `en-lecture,en-lecture,en-lecture,en-construction,en-cours,en-calcul` | pas de calcul : jamais `absent` |
| R11b | `indisponible,true,ok,ok,ok,pret,ok` | git `en-lecture` | idem |
| R15 | `ok,pret,ok` une fois la grâce passée | `en-lecture,en-cours,en-calcul` | la lecture sans signature ne part jamais |
| R16 | `tronque,true,true` | `en-construction,true,false` | pas de lecture de la frise |
| R17 | `1,1,true,true\|[["src/a.js",2]]\|true` | `0,0,true,false\|[]\|false` | pas de lecture des cibles |
| R18 | `500,702,true,true,true` | `0,0,false,false,true` | pas de collisions : rien à borner |

Verts sur la base, dits : `R8` (la boucle est libre parce que rien ne calcule : c'est le mutant `calcul-synchrone-dans-la-requete` qui établit que le témoin peut rougir), `R11`
(l'état `en-construction` est celui de la base ; la décision de fond vit dans `empreinte` de 75-03, couverte par sa suite : ici le témoin vérifie que la route la reporte),
`R12b` (garde de source : le module minimal ne contient aucune des formes interdites), `R4b` (le validateur conforme sur l'objet minimal). Sur la base, douze des treize mutants de cas rendent « ancre absente » (`mutant … invalide`) : un mutant invalide est un FAIL, jamais un rouge ; seul
`null-traite-comme-vide` s'applique (la constante existe déjà) et rougit, de même que les deux mutants de source (`lecture-propre-du-lab`, `chemin-decode`) : trois rouges, `7` avec ceux de la tâche 1.

Vert après le module complet : `25 PASS / 0 FAIL`, 93 s (`19` mutants rouges cumulés).

Mutants (rejoués : un cas en node sur une copie des scripts, l'ancre à exactement une occurrence, `node --check` ; un cas qui lève n'est jamais pris pour un rouge) :

| Mutant | Garde retirée | Témoin | Raison du rouge |
|---|---|---|---|
| `signature-relue-par-requete` | clé de cache lue en mémoire (A31) | R6 | un `rev-parse` par requête : le journal du binaire grossit alors que `git.sig` ne bouge pas |
| `cache-par-cle-retire` | recalcul seulement si la clé change | R6 | chaque requête relance le journal git |
| `mono-vol-retire` | un seul calcul en vol | R7 | trois requêtes concurrentes lancent trois `log` |
| `calcul-synchrone-dans-la-requete` | calcul hors requête | R7, R8 | la requête attend (1,5 s) : réponse non immédiate, écart de ticks > 250 ms |
| `chemin-comme-cle-d-objet` | tuples, jamais de clé dynamique | R9 | `gardes` devient un objet à clés de chemin : `fil` est une clé interdite, 503 `emission-refusee` |
| `source-arbres-non-fusionnee` | source `arbres` (P75-D-30) | R13 | la source disparaît de `collisions` |
| `worktree-verifie-compte-hors-lab` | worktrees vérifiés admis (A45) | R14 | la cible du worktree `wt` est comptée hors lab |
| `null-traite-comme-vide` | `git` nul = en lecture (A47) | R15 | `git.etat` vaut `vide` : tableaux vides présentés comme complets |
| `tronque-ignore` | frise tronquée dite | R16 | l'empreinte reste `ok`, radar complet |
| `cibles-tronque-ignore` | voies à cibles coupées comptées | R17 | `voiesCiblesTronquees` vaut 0 |
| `cibles-entieres-d-une-voie-tronquee-non-jointes` | cibles entières jointes (P75-D-31) | R17 | la collision `src/a.js` de la voie tronquée disparaît |
| `exception-d-un-module-non-contenue` | une exception = `indisponible` sur la lentille seule | R11b | l'exception remonte au filet : tout l'objet devient `indisponible`, git et branches compris |
| `borne-de-la-reponse-retiree` | réponse bornée à 500 collisions | R18 | 700 tuples servis |
| `lecture-propre-du-lab` | aucune lecture du lab par le module | R12b | `node:fs` apparaît dans le module |
| `chemin-decode` | aucun chemin décodé | R12b | `decodeURIComponent` apparaît dans le module |

## Tâche 3 — témoin d'export à marqueur unique, avec son témoin positif (A25)

Base : `97e821f3`. Marqueur : `MQ-` suivi de douze hexadécimaux tirés à chaque exécution (jamais un littéral du dépôt, jamais imprimé : la suite ne l'écrit pas) ; il nomme la branche du lab,
donc il figure à la fois dans une collision de branches de `/api/vf/activite` et dans l'en-tête git de `graph.json` (`meta.vfGit`, que l'export retire).

| Témoin | Résultat | Note |
|---|---|---|
| X0 | vrai | le marqueur est dans la réponse de la route ET dans `graph.json` : un export qui ne retirerait rien le porterait (sans cela X1 serait vide) |
| X1 | vert d'emblée | export en ligne de commande et par `/api/export` : zéro occurrence ; les deux exports existent et portent le graphe. Vert sur la base : l'export ne reçoit déjà rien de l'objet d'activité (aucun import), ce que X4 dit par la source de `serve.mjs` |
| X3 (mutant) | rouge | `export-garde-vfgit` : copie du module où l'export garde `g.meta` entier, vérifiée chargée (code 0), le marqueur SORT de l'export : X1 rougit, pour la bonne raison (l'export existe et porte le graphe) |
| X2 (positif) | vrai | le même marqueur, posé dans le nom d'un fichier du lab décrit par la page Code, apparaît dans l'export : X1 ne prouve donc pas « le marqueur ne sort jamais par aucun chemin » à vide |
| X4 | vert | `serve.mjs` ne nomme pas l'activité |

Le correctif d'une fuite irait dans le module d'export de la 79 (hors plan) : aucune fuite constatée, rien à remonter. Vert : `30 PASS / 0 FAIL`, 95 s, `20` mutants rouges cumulés (4 + 13 + 2 de source + 1).
Écart au plan : le plan voulait « une cible d'empreinte » dans les données ; une cible d'empreinte a toujours une carte (le radar ne rend que des chemins à carte), donc son nom est aussi dans `graph.json` et
dans l'export légitime : elle ne peut pas servir de marqueur de fuite. Le nom de branche, lui, n'est pas une donnée exportée (retirée avec `vfGit`).

## Correctifs d'audit (mandat de correction ciblée du manager) : F1 à F5

Base du rouge : `d3ffa525`. Suite rejouée en `TOUT=1` sur une copie dont le module, le module des gardes et le contrat sont ceux de cette base : `29 PASS / 6 FAIL` (les
quatre témoins neufs R19 à R22 et R6 rouges ; R21 par plantage : `creerRouteActivite` n'existe pas ; les mutants dont l'ancre n'existe pas sont « invalides », jamais des rouges).

| Témoin | Attendu | Obtenu sur la base | Raison |
|---|---|---|---|
| R19 (F1) | `true\|ok,3000,true` (boucle libre, liste bornée) | `false\|ok,8000,` | le calcul des gardes gèle la boucle (écart de ticks > 250 ms) et sert 8 000 gardes sans borne |
| R20 (F1) | `true\|tronque,0,true` | la lentille calcule tout | pas de plafond de travail |
| R21 (F2) | réponse < 1 Mo, 10 noms, sérialisée une fois | cas levé (`creerRouteActivite` absente) | la sérialisation n'existe pas ; noms non bornés |
| R22 (F3) | `indisponible,pret\|0\|true\|ok,ok,pret` | `indisponible,pret\|0\|false\|indisponible,ok,pret` | aucune reprise après l'échec |
| R6 (F4) | `0,1,1,,0,true` | `0,1,1,,0,false` | `git ls-files` ne passe pas par l'option `binaire` : l'espion ne le voit pas |
| R2b (F5) | `aucune` | vert (propriété déjà vraie) | le témoin par la propriété est neuf ; ses mutants (`import 'fs'`, `import('node:fs/promises')`, import d'un contrôle d'accès, lecture d'un en-tête) rougissent là où les grep d'origine ne les voient pas |

Vert après correctif : `35 PASS / 0 FAIL`, 214 s, `35` mutants rouges (20 + 11 de cas + 4 de propriété). Mutants neufs, chacun rouge par la propriété :

| Mutant | Propriété | Témoin |
|---|---|---|
| `gardes-sans-cession` | boucle libre pendant un calcul volumineux | R19 (écart de ticks mesuré 3 846 ms contre 26 ms) |
| `gardes-sans-plafond` | plafond de travail : `tronque`, jamais une liste partielle | R20 |
| `noms-par-tuple-non-bornes` | au plus 10 noms par tuple | R21 |
| `serialisation-a-chaque-requete` | aucun `stringify` par requête une fois la dérivation faite | R21 |
| `controle-vide`, `controle-integral` | squelette de contrôle = mêmes clés que la réponse et < 5 Ko | R21 |
| `plafond-d-octets-retire` | un plafond d'octets mordu réduit et le dit | R21 |
| `reprise-retiree`, `reprise-sans-delai` | reprise après le délai, jamais de tempête | R22 |
| `contexte-des-gardes-relu-a-chaque-graphe` | le graphe seul qui change ne lance aucun git (survivait sur la base : l'espion ne voyait pas `ls-files`) | R6 |
| `ls-files-hors-de-l-option-binaire` | toute invocation git passe par `binaire` | R6 |
| `import-fs-sans-prefixe`, `import-dynamique-de-fs-promises`, `import-d-un-controle-d-acces`, `lecture-d-un-en-tete` | aucune lecture de fichier, aucun contrôle recopié, quelle que soit la forme | R2b |

Deux erreurs de ma suite relevées et corrigées en route (prédicat de rouge inversé sur `gardes-sans-cession`, seuil de comptage de `stringify` trop haut) : les mutants avaient survécu, c'est ce qui les a montrées.
