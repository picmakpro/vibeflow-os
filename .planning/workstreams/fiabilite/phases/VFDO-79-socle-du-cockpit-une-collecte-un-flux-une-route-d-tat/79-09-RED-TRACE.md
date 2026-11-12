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
