AVANT cb5f353991c78293fb630272b20ba96d75f62cc5
# 77-03 — trace rouge (témoins posés avant le code)

Départ (mesures avant la tâche 1) : `vf-cockpit-server.mjs` 204 lignes, `vf-cockpit-paths.mjs` 166 lignes. Référence de la Phase 79 : la base de la mission
(79-05 : table `ROUTES` et répartiteur ; 79-07 : lanceur `vf-cockpit-git-lanceur.mjs` ; 79-02 et 79-06 : `socle-serveur.sh`) est présente dans la branche.

## test-cockpit-jauges.sh sur le code de départ (module et route absents) — 40 FAIL

- JP1 à JP14 : le module pur ne charge pas (`vf-cockpit-jauges.mjs` introuvable) ; chaque assertion JP rend `false`.
- JH1 — assertion : GET /api/vf/methode avec le jeton, 200 et onze jauges dans l'ordre de TYPES ; attendu `200|vibeflow/cockpit-jauges@1 state,state-prose,…,socle` ; obtenu `404|illisible`.
- JH4, JH5 : même cause (route absente, schéma non déclaré).
- JR1a — assertion : argv des deux gates (`--root <lab> --no-remote --format=tsv`, `--path <lab> --format=tsv`) ; obtenu : journal vide (aucun gate lancé).
- JR3.1 — sonde positive d'un lancement : attendu `1` ; obtenu `0`. JR3.2, JR3.4 à JR3.6 : mêmes causes.
- JR4 — non-gel : le GET de la route dure moins de 2 s (404) ; sonde positive en défaut.
- JR5a, JR5b — corps de la route : attendu `200|propre` ; obtenu `404|propre` (le 404 ne prouve rien : la sonde positive JR5.0 est verte, le marqueur est bien dans la sortie texte du vrai gate).
- JR6, JR8a, JR8b, JR8c : route absente (404) ou module absent.
- JR9a à JR9d : le serveur ne rend rien d'exploitable sur la route (404).
- JR10c — assertion : aucun GIT_* hérité dans l'environnement du faux gate ; attendu `0|1|<lab>` ; obtenu `||` (le gate n'est jamais lancé).
- Mutants M-CHEMIN et M-ENV-GIT : construction impossible sur la base (le fichier à muter n'existe pas), donc FAIL nommés.
- Verts à la base : JH2a, JH2b (403 du portail), JH3 (405 du répartiteur), JR3.0, JR5.0 (sondes positives).

## test-cockpit-routes.sh, rejeu après l'ajout de la ligne de table, AVANT de toucher la liste de RK.1

- RK.1 — assertion : les chemins de `ROUTES` égalent la liste écrite à la main ; attendu `ok` ; obtenu `ko` (les chemins de la liste plus `/api/vf/methode`).
- RK.7 — attendu `aucun-echec|7|7` ; obtenu `aucun-echec|8|8` (la classe sonde la route : 403, 405, no-store, JSON, sans CORS).
- M-LITTERAL, M-HISTORIQUE-NEUF, M-ORDRE : RK.1 rougit en plus de la sonde isolée (la liste attendue des mutants suit celle de RK.1).
- Correctif : `/api/vf/methode` ajouté à la liste de RK.1, à sa place alphabétique, et le décompte de RK.7 passé à 8 ; rejeu : 56 PASS / 0 FAIL.
