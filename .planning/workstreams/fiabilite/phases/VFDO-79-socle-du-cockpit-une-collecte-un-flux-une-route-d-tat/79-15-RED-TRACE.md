AVANT-15 238aed8b98267212484480ee1cac8d3943403193

# 79-15 — trace des rouges (régime allégé : témoin rouge puis vert, aucun mutant, aucune propriété générative)

## Tâche 1 — rouges sur le code présent (tête 238aed8b)

Baselines : `renameSync` dans `vf-cockpit-live.mjs` = 1 ; import du module d'embarquement dans `vf-cockpit-live.mjs` = 1 ; `vf-cockpit-server.mjs` = 210 lignes ;
lectures de `project.html` comptées par la sonde sur le serveur présent (démarrage + trois changements + trois pages) = 8 (le plan annonçait « au moins 7 »).

`test-cockpit-graphe.sh` : 6 PASS / 13 FAIL.

| Assertion | Attendu | Obtenu | Raison |
|---|---|---|---|
| G1.1 | 200, ETag, schéma Projet | rien (404) | route absente |
| G1.2 | 304 sur If-None-Match égal | rien | route absente |
| G1.3 | ph-2 done et ETag différent | vide | route absente |
| G1.4 | project.html figé après patch et structure | écrit | page réécrite par le direct |
| G1.5 | projet.json 0600 égal à la route | absent | fichier absent |
| G1.6a / G1.6a2 | événement graphe projet, sig = ETag | aucun | événement absent |
| G1.7b | données de la page = corps de la route | route vide | route absente (G1.7 lui-même vert sur la base) |
| G1.8a / G1.8b | l'outil suit projet.json ; erreur exit 1 sinon | lit la page, exit 0 | l'outil lit project.html |
| G1.9 | 1 lecture de project.html | 8 | relecture et analyse à chaque événement |
| G1.10a / G1.10b | projet.json recréé en 0600 | absent | fichier absent |

Verts sur la base, par construction (témoins) : G0.1, G0.2 (la sonde compte), G0.3, G1.2b (ETag vide des deux côtés, gardé par `-n` désormais), G1.6b (aucun événement : vrai tant que l'événement n'existe pas).

Suites de l'ancien contrat réécrites (libellé et rôle gardés) :

| Suite | Assertion | Résultat sur la base |
|---|---|---|
| `test-cockpit-direct.sh` | D2.5 (project.html du disque inchangé, route à jour), D3.3, D3.6 (.tmp et projet.json), D4.2 (route garde la mission) | 4 FAIL / 72 PASS : route absente, page réécrite |
| `test-cockpit-assemblage.sh` | A1 (projet.json attendu), A1.2a (schéma, 0600) | 2 FAIL / 53 PASS : fichier absent |
| `test-cockpit-git-entete.sh` | H2.3a (page servie porte le plan, disque inchangé), H2.3b (vfGit de la page servie), H2.3c | non rejouée sur la base (Chrome) ; rouge par construction : le disque est réécrit par le direct, H2.3a attend 0 |
| `test-cockpit-securite.sh` | marqueurs hostiles avec `VF_COCKPIT_DONNEES_GABARIT=1`, témoin de présence X0 | non rejouée sur la base (Chrome) ; X0 vert sur la base (la page est le fichier), le réglage n'y fait rien : sans effet, jamais un vert à vide une fois la page servie de l'instantané |

Rouges de base : aucun hors de ce plan.
