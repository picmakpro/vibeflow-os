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
