AVANT-09 cbffb929

# 79-09 — trace des rouges

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-collecte.sh`, jouée sur le code présent (AVANT-09 : aucun module de la collecte hors boucle, aucun instantané). Dossier temporaire et `TMPDIR` pointés hors de celui de l'utilisateur.

## Tâche 1 — témoins rouges sur le code présent

Bilan sur le code présent : 7 PASS / 16 FAIL. Verts d'emblée, voulus (contrôles positifs d'entrée et gardes) : C0.0, C0.1, C0.2, C1.4, C1.5, C1.1a, H0.

- C1.1 — latence maximale d'une requête légère (GET toutes les 100 ms, 8 s) pendant un tour dont le verrou dort 3 s | attendu : < 200 ms | obtenu : 3048 ms (79 réponses, aucune erreur de connexion, p99 3048) : le tour du filet fige la boucle.
- C1.2a — `GET /api/vf/etat` juste après l'écoute : `collecte.etat` | attendu : `en-cours` | obtenu : `undefined` (le champ `collecte` est absent).
- C1.2b — puis `collecte.etat`, `derniereA` ISO, `dureeMs` entier positif | attendu : `ok true true` | obtenu : illisible (`collecte` absent).
- C1.2c — `collecte.mode` et `collecte.clients` | attendu : `true 1` | obtenu : illisible.
- C1.3 — délai entre la connexion du client et `hello` (verrou à 3 s) | attendu : au moins 500 ms | obtenu : 5 ms (la collecte de démarrage a eu lieu avant l'écoute : la boucle était bloquée avant que le serveur n'écoute).
- C10.1 à C10.4 — `instantane`, `poser`, `surInstantane` | attendu : `true` | obtenu : `false` (module `vf-cockpit-instantane.mjs` absent).
- C10.5 — le module existe et n'importe aucun module de la collecte | attendu : `oui` | obtenu : `non` (module absent).
- C10.6a, C10.6b, C10.6c, C10.7a, C10.7b, C10.7c — instantané et signature git (A47) | attendu : `true` | obtenu : `undefined` (le harnais plante : `ERR_MODULE_NOT_FOUND` sur `vf-cockpit-instantane.mjs`).

Témoins positifs d'entrée verts sur le code présent (le faux verrou est bien appelé et la session de fixture figure dans `hello`) : C0.1 `1 >= 1`, C0.2 `0 1`. C1.4 : exactement un `status` 5,7 s après `hello` (vert avant et après). C1.5 : serveur sorti en moins de 5 s.

### Tâche 1 — état vert (code livré)

`test-cockpit-collecte.sh` : 23 PASS / 0 FAIL (rejouée seule, deux fois, la seconde sous une charge machine de plus de 20). Mesures du code livré, mêmes conditions que le rouge (verrou à 3 s, un client SSE connecté, GET léger toutes les 100 ms pendant 8 s) :
- C1.1 : 78 réponses, aucune erreur, p99 10 ms, maximum 10 ms (4 ms au premier rejeu) ; sur le code présent : maximum 3048 ms.
- C1.3 : `hello` arrive 2934 ms après la connexion (il attend la première collecte) ; sur le code présent : 5 ms.
- C1.2 : `collecte.etat` vaut `en-cours` juste après l'écoute, puis `ok` avec `derniereA` ISO, `dureeMs` entier positif, `mode` `watch` ou `poll`, `clients` 1.
- C10.1 à C10.5 : instantané nul avant la première pose, gelé en profondeur (témoin : modifiable avant la pose), rappels isolés, aucun import de la collecte.
- C10.6, C10.7 : `git` nul à la première pose (celle du graphe), puis `{ sig, at }` ; même `sig` et `at` qui avance sur deux calculs ; un commit vide change `sig` et l'événement `git` porte le même ; 200 lectures n'appellent pas git ; un calcul qui échoue ne remplace pas la valeur.

Régression : `test-cockpit-cycle-serveur.sh` 91 PASS / 0 FAIL avec le collecteur en ligne injecté et les attentes `live.pret` (H2.0 à H2.8 verts). Suites qui nomment `vf-cockpit-live.mjs` ou `vf-cockpit-server.mjs`, rejouées chacune seule : voir le SUMMARY.

Deux défauts de la suite trouvés au rejeu sous charge et corrigés AVANT le commit vert : (1) C10.6a dépendait d'un délai de 1,5 s du faux git, trop proche de l'échéance globale de 2 s de la signature (retrait de 5 s si dépassée) : la première pose est maintenant vue par un rappel `surInstantane` posé avant le démarrage, sans délai ; (2) les attentes de C10.6 et C10.7 passent de 9 et 12 s à 15 et 20 s.

Correction de chiffres : le message du commit des suites routes et git-env écrit « routes 57/0, git-env 136/0 » ; les bilans réels des deux suites rejouées seules sont routes 56 PASS / 0 FAIL et git-env 135 PASS / 0 FAIL (le décompte du message comptait la ligne de bilan).

## Tâche 2 — témoins rouges sur le code de la tâche 1

AVANT-09-T2 : 66a9af10 plus les tests (commit des aides et sections C2 à C4). Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-collecte.sh`, `TMPDIR` hors du dossier de l'utilisateur. Bilan sur le code de la tâche 1 : 40 PASS / 23 FAIL (le détail ci-dessous nomme chaque rouge ; les 40 verts sont les sections C0, C1, C10 de la tâche 1 et les verts d'emblée nommés plus bas).

Verts d'emblée, voulus ou constatés : C2.1 (le pilote de la tâche 1 coalesce déjà : deux exécutions, union des motifs), C2.6b (témoin positif), C2.7 (arrêt sans fuite), C3.0 (le code de départ f763b556 est lent, la mesure sait rougir), C3.1 en entier (voir la note), C4.2 : rien de l'index n'existe encore, donc rouge, pas vert.
- C3.0 — code de départ, GET toutes les 100 ms pendant 14 s, faux verrou à 0,4 s, fixture de 52 Mio : n 138, erreurs 0, p50 1, p99 398, max 448, pics 448 398 346 297 246 (ms). Assertion : max >= 300 ; obtenu 448.
- C3.1 sur le code de la tâche 1 : p50 1, p99 2, max 5 (ms), VERT. Note de lecture : le fil de la tâche 1 ne porte pas encore l'index, donc le remplissage de 50 Mio n'a pas lieu ; la mesure de C3.1 rougit sur la base (C3.0) et rougira sur le mutant « en ligne » (M-EN-LIGNE, qui rejoue les étapes de la tâche 2 sur la boucle) ; le rouge propre de C3.1 sur « code présent » n'existe donc que contre la base, ce que le plan appelle « en partie ».
- C2.2 — attendu `true partielle suspendu 1 true 2` ; obtenu `undefined … false undefined` (pas de relance : le pilote ne sait pas relancer).
- C2.3 — attendu `true true true ok true` ; obtenu `true false false indisponible undefined` (pas de reprise).
- C2.4 — attendu `true memoire` ; obtenu `true undefined` (cause non classée).
- C2.5 — attendu `true 2` ; obtenu `undefined undefined` (`redemarrer` absent).
- C2.6a — attendu `partielle 0 0` ; obtenu `ok 1 0` (un résultat à clé interdite est accepté dans « qui »).
- C3.2 — `collecte.boucle.maxMs` : illisible (moniteur absent). C4.1 : `collecte.index` illisible. C4.2a : attendu `600 lu 64`, obtenu `absent absent 0`. C4.2b : fichier d'index absent. C4.3 : attendu `identique`, obtenu `different` (fichier absent). C4.2c : attendu `0/0`, obtenu `1/0` (le marqueur figure dans le flux : la ligne de transcript est vue par le collecteur d'équipe de la tâche 1, constaté, voir C4.2c du vert). C4.4b : `collecte.index` illisible.
- C4.7b — attendu `true true`, obtenu `false false` (module de l'étape d'index absent). C4.8a à C4.8d : `illisible` (module absent).
- Mutants : tous « construction du mutant » en échec sur le code de la tâche 1 (les ancres `garde:collecte-ecrivain`, `garde:collecte-sans-index`, `garde:index-arbre`, `garde:index-collision` n'existent pas encore ; M-EN-LIGNE vise `fil.w.postMessage`) ; M-GEL et M-GIT sont verts d'emblée sur leurs ancres de la tâche 1.

### Tâche 2 — état vert (code livré)

`test-cockpit-collecte.sh` : 63 PASS / 0 FAIL (rejeu seul, charge machine de 7 ; les rejeux faits pendant une charge de 120 à 350 ou à cheval sur la veille du poste sont nuls et écartés).
- Latences (GET toutes les 100 ms, 14 s, faux verrou à 0,4 s, fixture de 52 Mio) : base f763b556 : p50 1, p99 449, max 460 ms (pics 460 449 358 349 256) ; code livré : p50 1, p99 2, max 4 ms ; vrai serveur : p99 2, max 4 ms ; mutant en ligne : p99 463, max 503 ms ; ligne géante (34 Mio) : max 5 ms, `collecte.etat` partielle, `index.tronque` vrai. `collecte.boucle.maxMs` < 100.
- Mutants (copie du module, `cmp` différent, charge, rouge sur la bonne mesure) : M-EN-LIGNE (`garde:collecte-fil`, `fil.w.postMessage(enVol);` remplacé par l'exécution des étapes sur la boucle : max 503 ms, aucune erreur de connexion) ; M-ECRIVAIN (`garde:collecte-ecrivain`, `await ancien.sorti;` retiré : ordre du journal faux) ; M-RELANCE (`garde:collecte-sans-index`, `lancer(true)` devient `lancer(false)` : indisponible au lieu de partielle) ; M-GEL (`Object.freeze(o);` retiré : C10.2 faux, C10.1 vrai) ; M-GIT (le rangement de `gitInfo` retiré : C10.7a faux, événement git émis) ; M-ARBRE-DECLARE (`worktreeVerifie(commun, chemin)` devient `true` : le leurre 1 obtient une voie, les cas (a) et (c) restent verts) ; M-COLLISION (`compte.get(n) > 1` devient `false` : le doublon obtient une voie, le cas (a) reste vert).
- Rouges corrigés dans la suite avant le vert (défauts de la suite, pas du code) : préfixe de mutant non cité, dossier de travail réutilisé par les mutants d'arbre, marqueurs de fuite trop larges (voir l'amendement du plan).

## Tâche 3 — témoins rouges sur le code de la tâche 2

AVANT-09-T3 : voir le sha de HEAD relevé au commit des témoins (aucun code de la tâche 3 écrit). Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-collecte.sh`, `TMPDIR` hors du dossier de l'utilisateur. Bilan sur le code de la tâche 2 : 66 PASS / 27 FAIL (les 63 verts de la tâche 2, plus C5.0, C5.2a et C11.1, verts d'emblée voulus ; les 27 rouges ci-dessous, mutants compris). Graines jouées au rouge : rattachement 1381222893, signature 1381224209 (la graine n'influe pas sur les rouges : les modules sont absents).

- C5.1 — `hello.who.workers` de wk01 (agent consigné puis clos par le vrai `driver-lock.sh`, verrou relâché ; DAG du lab portant `n-revue`) | attendu : `rattache|registre|n-revue|.planning/missions/m-revue.dag.json` | obtenu : `non-rattache|||` (le registre courant a disparu au relâchement, l'archive n'est pas lue : raison `sans-citation`).
- C5.2b — `lireRegistre` sur un script sans le verbe | attendu : `absente` | obtenu : `module-absent`. C5.2a (la collecte réussit, l'agent dont le mandat cite son nœud est rattaché par `mandat`) : vert d'emblée, contrôle positif de la dégradation.
- C5.3a à C5.3g — identifiants et statuts hors forme, jeton masqué, 5 000 agents au plus, doublon (`running` puis `epoch`), sorties illisibles, bornes, fusion | attendu : `lue|ok1`, `true,true`, `lue|5000`, `A,D`, `erreur:0,erreur:0,erreur:0,erreur:0,absente:0`, `128,80,128`, `p1:orphelin,p2:n2` | obtenu : `undefined` partout (module `vf-cockpit-registre.mjs` absent).
- C6.1 — `rattacherVoies` contre l'oracle de la suite | attendu : `0,0,0,0,0,0` écarts | obtenu : `-1,-1,-1,-1,-1,-1` (module absent) ; C6.couverture attendu `true`, obtenu `false`. C6.2 — voie de wk01, `rattachement`, égalité avec `signal.missions[].fichier` | attendu : `true registre|n-revue true` | obtenu : `true absent false` (la voie existe dans l'index, aucun rattachement n'y est joint).
- C7.1 — `finMotif` des sessions `failed`, `stopped`, `done`, `working` | attendu : `fm-fail:termine:echec fm-stop:termine:arret fm-done:termine: fm-live:actif:` | obtenu : `fm-fail:termine: fm-stop:termine: fm-done:termine: fm-live:actif:` (l'état reste `termine`, la cause est perdue). C7.2 — `sortisSilence` de cinq sous-agents de silences connus | attendu : `1 sil-b,sil-c,sil-d` | obtenu : `undefined sil-b,sil-c,sil-d` (le champ est absent ; les agents retenus sont déjà les bons). C7.3 — contrat | attendu : `true true ["echec","arret"] {"failed":"echec","stopped":"arret"}` | obtenu : `false false  ` (aucune des quatre déclarations).
- C8.1 à C8.3 — signature du who | attendu : liste `true` ; `0,0,true` ; `true,true,true` | obtenu : `undefined`, `illisible`, `,,` (module `vf-cockpit-who-signature.mjs` absent ; la signature actuelle énumère onze champs).
- C11.2 à C11.5 — journal des lancements du scan après chaque geste sur un moteur d'essai (copie du module dont `scan.mjs` consigne chaque lancement) | attendu : 1, 2, `3 4`, `5 6` | obtenu : 2, 3, `4 5`, `6 7` (le scan est relancé à chaque assemblage, y compris sur un lab inchangé). C11.1 (le premier assemblage lance le scan : 1) : vert d'emblée.
- Mutants M-ENFANTS, M-SILENCE, M-SILENCE-FENETRE, M-VOLATILS, M-CACHE : « construction du mutant » en échec (les modules `vf-cockpit-voies-rattachement.mjs`, `vf-cockpit-who-signature.mjs`, `vf-cockpit-code-cache.mjs` n'existent pas ; les ancres `garde:equipe-silence` et `garde:equipe-fenetre` n'existent pas encore dans `vf-cockpit-equipe.mjs`).

Défaut de la suite relevé et corrigé avant ce commit : `mktemp -d` sans modèle ignore `TMPDIR` sous macOS (le dossier de la suite tombait dans le dossier temporaire de l'utilisateur malgré la règle 11) ; le dossier de la suite est maintenant `mktemp -d "$TMPDIR/tmp.XXXXXXXXXX"` (même forme « tmp.<alphanumérique> » que la marque d'hygiène lit). Réancrage de M-W23-SIG dans `test-cockpit-who.sh` : la ligne `garde:who-volatils` du module de signature remplace l'énumération de `vf-cockpit-live.mjs` (elle rougit tant que le module n'existe pas, et tue le même comportement qu'avant une fois posé : titre neutralisé dans la signature).
