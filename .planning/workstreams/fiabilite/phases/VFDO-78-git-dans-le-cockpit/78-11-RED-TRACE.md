# 78-11 — traces de rouge

Commande de base : `E2E_SECTIONS="MJ" bash plugin/cockpit/scripts/tests/test-cockpit-git-e2e.sh` (serveur réel, Chrome headless en CDP, port éphémère). Chaque mutant est posé sur une COPIE de la sortie assemblée (`<lab>/.vibeflow/mut-<nom>/`, racine du lab = deux niveaux au-dessus), jamais sur le module ; `mut.mjs` échoue si le motif est absent ou multiple (un mutant sans effet ne compte pas).

## Tâche 1 — mutants de jonction (rouge joué AVANT la suite complète)

| Mutant | Mutation | Assertion rouge | Attendu | Obtenu |
|---|---|---|---|---|
| M-ROUTE | `vf-cockpit-server.mjs` de la copie : `if (routeGit(req, res, url, { root, json })) return true;` -> `if (false) return true;` | B2 (route réelle, graphe) | `GET /api/vf/git` = 200, schéma `vibeflow/cockpit-git@1`, rangées de la page = rangées de la route (8) | route 404 (`[404,null,null]`), 0 rangée affichée ; le tiroir s'ouvre pourtant au clic (`ouvert-clic` mesuré) : la page, la seconde ligne et le tiroir existent, seule la route est coupée |
| M-SIGNAL | `index.html` et `project.html` de la copie : `es.addEventListener('git',` -> `es.addEventListener('git-mort',` (relais de l'événement `git` retiré de 70-vf-live.js) | B3 (rafraîchissement réel) | une rangée neuve en tête en moins de 10 000 ms après un `git commit`, la seconde ligne dit `autre` après `git switch -c autre` | `rangee-neuve: false` (rangées 8 -> 8), `ligne-autre: false` (`feat/x · worktree wt-a`) ; B2 vert sur le même serveur (route 200, 8 rangées, g, détail, pastilles : aucune propriété fausse) |
| M-OUVREUR | `index.html` et `project.html` de la copie : `new CustomEvent('vf-git:basculer',` -> `new CustomEvent('vf-git:basculer-mort',` | B2 (ouverture) | tiroir ouvert au clic sur la seconde ligne, ouvert et fermé par g, rangées = route | `ouvert-clic: false`, `ferme-g: false`, `ouvert-g: false`, rangées 0 != route 8, première rangée != route ; la route répond 200 (le graphe existe côté serveur) |

Sortie des trois assertions de mutants : 3 PASS (la suite affirme que chaque mutant rougit sa section pour la raison nommée). Une première version du témoin B2/B5 a lu le détail pendant l'état « Lecture du détail » (assertion B2.3 et B5.1 rouges : `200|false|false|true|false`) : défaut de la suite, corrigé en attendant le contenu chargé, pas du code livré.

Vert après : suite complète, 34 réussis, 0 échoué, 0 sauté (B0, B1 x3 onglets, B2.1-2.5, B3.1-3.4, B4.1-4.3, B5.0-5.5, CAPT.1-2, trois mutants, H0).
