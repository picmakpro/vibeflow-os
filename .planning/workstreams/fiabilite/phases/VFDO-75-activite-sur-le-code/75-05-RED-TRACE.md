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
