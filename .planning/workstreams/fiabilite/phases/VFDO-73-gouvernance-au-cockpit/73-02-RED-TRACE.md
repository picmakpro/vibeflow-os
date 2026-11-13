base: c4053a32c8b09deb0c19e2afee9d4145e8edc0cf

# 73-02 — trace du rouge (régime allégé)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG13` (sections `RG13_officiel` et `RG13_route`), sur la base ci-dessus,
avant tout code de `ailleurs()` et de la route. Motif : l'export `ailleurs` et la route `GET /api/vf/ailleurs` n'existent pas.

## Témoins rouges (assertion, attendu, obtenu)

| Identifiant | Attendu | Obtenu |
|---|---|---|
| RG13.0 (témoin positif) | `[{"lab":"atelier","n":1}]` | `ERR m.ailleurs is not a function` |
| RG13.1 | `[[{"lab":"atelier","n":1}],[]]` | `ERR m.ailleurs is not a function` |
| RG13.2 | `[[],[{"lab":"lab-bis","n":1}]]` | `ERR m.ailleurs is not a function` |
| RG13.3 | atelier 2, forge 1, menuiserie 1 | `ERR m.ailleurs is not a function` |
| RG13.4 | `[["lab,n"],false,false,false]` | `ERR m.ailleurs is not a function` |
| RG13.4b | `[[{"lab":"atelier","n":1}],40]` | `ERR m.ailleurs is not a function` |
| RG13.5 | `[{"lab":"un autre dossier","n":3}]` | `ERR m.ailleurs is not a function` |
| RG13.6 | six `null` | `ERR m.ailleurs is not a function` |
| RG13.10 | `200\|vibeflow/cockpit-ailleurs@1\|[{"lab":"atelier","n":1}]` | `404\|\|` |
| RG13.13 | `oui\|0\|0` (précondition vraie) | `non\|0\|0` (la route n'a pas rendu la liste : précondition fausse) |

Les quatre mutants de fonction (M-AILLEURS-CWD, -TITRE, -SOUS-ARBRE, -HOME) rougissent sur la base par « ancre absente » (le code muté n'existe pas encore) ;
M-AILLEURS-GIT et M-ROUTE-PAR-REQUETE aussi. Ils sont rejoués et vus rouges par mutation du code livré (tâche 2).

## Gardes déjà vertes dès la base (contrôles existants de serve.mjs et du routeur)

- RG13.11 : POST avec jeton, 405 (le routeur rend 405 à toute méthode non GET sous `/api/vf/`).
- RG13.12 : GET sans jeton, 403 (portail de serve.mjs).
- RG13.14 : témoin positif (le serveur lance au moins un git dans un arbre du lab : `gitlab` > 0) puis aucun git hors du lab ni dans un autre lab.
- M-ROUTE-SANS-JETON : vu « tué » dès la base mais pour 404 au lieu de 403 (la route n'existe pas) ; la preuve réelle (403 sain, ≠ mutant servi) se refait sur le code livré.

## RK.1 (table des routes, A54)

`ROUTES` du serveur reçoit d'abord la ligne `/api/vf/ailleurs` ; `bash plugin/cockpit/scripts/tests/test-cockpit-routes.sh` rend alors :

- `RK.1` rouge : attendu `ok`, obtenu `ko` (la route de `ROUTES` n'est pas dans la liste écrite à la main) ;
- `RK.7` rouge : attendu `aucun-echec|7|7`, obtenu `aucun-echec|8|8` (le compteur de couverture est écrit en dur : 7 routes) ;
- trois mutants de la suite (M-LITTERAL, M-HISTORIQUE-NEUF, M-ORDRE) rougissent aussi, `RK.1` s'ajoutant à leur verdict attendu (leur liste dérive de `ATTENDU`).

Puis, à sa place alphabétique : `/api/vf/ailleurs` ajouté à `ATTENDU`, au libellé de `RK.1` et le compteur de `RK.7` porté à 8 : PASS RK.1, PASS RK.7, suite 56 PASS / 0 FAIL.

## Écart constaté en cours de tâche 2 (pas un rouge de témoin)

La collecte du cockpit lit `claude agents --json` dans un fil (worker) : la mémoire de `vf-cockpit-etat-officiel.mjs` du processus serveur reste vide, `ailleurs()` y rendait `null`
(obtenu `liste=null` malgré deux appels du faux claude). La route déclenche donc la lecture officielle du serveur par `demander` (au plus une par REPIT_MS, jamais une par requête) ;
RG13.13 et M-ROUTE-PAR-REQUETE (lecture relancée à chaque requête, `dclaude=10`) gardent cette borne.
