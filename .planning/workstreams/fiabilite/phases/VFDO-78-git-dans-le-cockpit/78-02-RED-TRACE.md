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

## Tâche 2 — G4, G5 et mutants sur la base (module de la tâche 1 : parseurs et `ordonner`, sans `placer`/`etiquettes`/`teinte`)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-graphe.sh` (rc=1, 23 passés, 27 échoués). Les 17 assertions G0-G3 restent vertes.

| Témoin | Assertion | Attendu | Obtenu |
|---|---|---|---|
| G4.1 | arêtes vers la colonne du parent, aucun couloir ouvert, 2 racines | `viol=0 ouverts=0 racines=2 rangees=33` | `sonde-ko M.placer is not a function` |
| G4.2 | octopus : 2 arêtes distinctes | `n=1 s=2 distincts=true fusion=true suite=true` | `sonde-ko M.placer is not a function` |
| G4.3 / G4.3b | fenêtre -n 10, couloirs ouverts | `egal=true listes=true racines=0 tort=0` | `sonde-ko …` / vide |
| G4.4f | témoin de déterminisme non vide | > 3000 octets | vide |
| G4.5 | 4 couloirs, `couloirsMax` 2 | `vus=4 max=3 replies0=0 \| max2=1 largeur2=2 replies2=true` | `sonde-ko …` |
| G4.6 / G4.7 | densité et perf ; branche mergée repliée | `rangees=1000 dense=true rapide=true` / `repli=true etiquette=locale:f` | `sonde-ko …` |
| G5.1 / G5.1b | ordre des étiquettes | `ordre=HEAD,a,b,origin/a,v1 …` | `sonde-ko M.etiquettes is not a function` |
| G5.2b | teinte 1..5 non constante | `dans varie` | `hors varie` (`teinte` absente) |
| Mutants M-ALIGN, M-PAQUET, M-OCTOPUS, M-RACINE, M-ORDRE | motif fixe présent une fois, sonde rougie | PASS | FAIL : motifs absents du module de base (ou `teinte`/`placer` absents) |

Note : G4.4b-e (cmp de deux sorties identiques) passent à vide sur deux sorties d'erreur identiques ; c'est G4.4f (taille > 3000 octets) qui garde contre ce vert à vide, et il est rouge ici.
Journal complet : scratchpad `78-02-rouge-t2.log`.
