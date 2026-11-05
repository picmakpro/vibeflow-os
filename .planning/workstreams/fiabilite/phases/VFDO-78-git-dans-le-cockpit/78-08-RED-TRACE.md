# 78-08 — traces des rouges (détail d'un commit, état des worktrees)

Reprise après le crash du 2026-11-05 : la suite `test-cockpit-git-details.sh` laissée par le prédécesseur (X1 seulement) a été relue contre le plan.
Un défaut de fixture corrigé AVANT de la rejouer : le lab n'avait pas de `.planning`, `vf-cockpit-build.mjs` refusait (« aucun dossier .planning trouvé »),
le serveur ne démarrait pas et les 26 assertions rougissaient pour une fixture morte. Après correction (lab GSD, `.planning` et `.vibeflow` dans `.git/info/exclude`),
X0.2 (serveur démarré, jeton lu) passe : le rouge ci-dessous vient donc de la seule absence de la route.

## Tâche 1 — rouge (route absente)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-details.sh`
Attendu : X1.1 à X1.5 en échec (aucun module, `/api/vf/git/commit` répond 404 comme toute route inconnue de `routeGit`).
Obtenu : `Résultats : 3 PASS / 25 FAIL` (PASS : X0.1 fixture, X0.2 serveur, H0 hygiène). Exemple : X1.1a attendu `200|vibeflow/cockpit-git-commit@1|ok|true|true`, obtenu `404|illisible` ;
X1.2 « sha court de 12 caractères » attendu `400|sha-invalide`, obtenu `404|illisible`.
