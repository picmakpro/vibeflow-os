# 79-03 — trace des rouges

Base de départ des témoins : `driver-lock.sh` non modifié (base `integration/cockpit-audit`, verbe `registry` inconnu,
`release` qui supprime le registre par `rm -f`).

## Tâche 1

Commande : `bash plugin/conductor/scripts/tests/test-driver-lock.sh` sur la base. Résultat : 264 PASS / 31 FAIL, exit 1.
Les 31 FAIL sont tous des assertions neuves (aucune assertion antérieure ne rougit). Le verbe `registry` inconnu rend
« Unknown arg: registry » sur stderr, exit 1, stdout vide : l'obtenu des assertions de contenu est la chaîne vide.

| Témoin | Assertion | Attendu | Obtenu sur la base |
|---|---|---|---|
| T63.8 | archive frère du registre après le release propre | `yes` | `no` (le registre est supprimé, aucune archive) |
| T63.9 / 9b / 9c | `registry` : JSON parsable, exit 0, `"present": true` | JSON, 0, `"present": true` | exit 1, sortie vide |
| T63.10a | count | `"count": 4` | sortie vide |
| T63.10b | ag-reviewer, nœud | `revue-A` | vide |
| T63.10c | ag-reviewer, statut | `stopped` | vide |
| T63.10d / 10e / 10f | ag-planner : rôle, parent, statut | `gsd-planner`, `ag-coder`, `failed` | vide |
| T63.10g / 10h | ag-coder `done`, ag-deep `stopped` | `done`, `stopped` | vide |
| T63.11e | sortie de `registry` sans chemin du poste (et non vide) | sortie non vide | sortie vide |
| T63.12c | archive non écrivable : registre courant conservé avec 2 lignes | `2` | `absent` (supprimé par `rm -f`) |
| T63.12e | stderr du release | `registre non archivé` | vide |
| T68.1a-d | sans registre ni archive : `present false`, `count 0`, `agents []`, exit 0 | idem | vide, exit 1 |
| T68.2a / 2b / 2c | agent ré-enregistré : une fois, `running`, nœud `n-new` | `1`, `running`, `n-new` | vide |
| T68.3c | enfant `running` encore rendu par `registry` | `running` | vide |
| T68.4a | chaque entrée porte exactement les dix clés | `0` entrée non conforme | vide |
| T68.4b (x5) | clés refusées absentes d'une sortie non vide | sortie non vide | sortie vide |
| T68.4c / 4d | archive falsifiée : JSON valide, valeur de `role` réduite | JSON valide, valeur sans guillemet ni antislash | exit 1, vide |

Verts d'emblée sur la base (contrôles positifs, ils doivent le rester) : T63.7 (registre courant supprimé par un release
propre), T59 à T66 en entier, T63.11a-d (lecture seule : sommes de contrôle et liste du dossier identiques, `orphans`
`"present": false` et `"count": 0`), T63.12a-b et T63.12d (le release relâche, exit 0, le dossier qui occupe le nom de
l'archive est intact), T68.3a-b (release avec un enfant `running` : archive non touchée, registre courant gardé).

Transcription WS-AB (`DLWS_MODE=matrice bash plugin/conductor/scripts/tests/test-driver-lock-ws.sh`) sur la base :
653 ok, 0 ko, exit 0, 36 s (contrôle positif avant le code).

Durée de la suite `test-driver-lock.sh` sur la base : environ 23 s.
