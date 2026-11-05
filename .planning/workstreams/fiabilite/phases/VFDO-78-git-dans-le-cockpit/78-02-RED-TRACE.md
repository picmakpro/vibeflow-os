# 78-02 — trace des témoins rouges

Note de méthode : un brouillon du module avait été écrit avant la suite ; il a été déplacé hors du dépôt (scratchpad) AVANT de jouer le rouge, puis restauré après. Le rouge ci-dessous est donc celui d'un module absent.

## Tâche 1 — G1 à G3 sur la base (module absent)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-graphe.sh` (rc=1, 5 passés, 12 échoués).

| Témoin | Assertion | Attendu | Obtenu |
|---|---|---|---|
| G0.1-G0.5 | contrôles positifs de la fixture (33 commits sur main, 1 octopus, 2 racines, 3 worktrees) | vert | vert (la fixture est vivante) |
| G1.1 | 25 commits lus, parents au motif | `ok 25` | `charge-ko` |
| G1.1b | mêmes sha que `git rev-list --topo-order -n 25` | liste des 25 sha | `charge-ko` |
| G1.2 | coupes dans le dernier enregistrement | `0 <total>` | `charge-ko` |
| G1.2c | frontière exacte | `24` | `charge-ko` |
| G1.3 | sha de 39 car., at non entier, parent mal formé | `ko ko ko ok` | `charge-ko` |
| G2.1 / G2.1b | 4 champs ok, 3 champs ko, tag pelé, noms | `ok:N ko ko pelees=1` | `charge-ko` |
| G2.2 / G2.2b | 3 worktrees, détaché, branche, chemins | `n=3 b0=refs/heads/main d1=true b2=refs/heads/wtb …` | `charge-ko` |
| G3.1 / G3.2 | ordre topologique stable, égalité de date, horloge décalée | `33 33 viol=0 stable=true` / `ties=37abce egal=fa skew=312` | `charge-ko` |

`charge-ko` = l'import du module échoue (fichier absent). Journal complet : scratchpad `78-02-rouge-t1.log`.
