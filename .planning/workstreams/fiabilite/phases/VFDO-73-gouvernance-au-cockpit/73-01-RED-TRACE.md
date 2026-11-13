# 73-01 — trace du rouge (régime allégé)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG4 RG5 RG7 RG10` sur la base (faed809d + lanceur et fragment, module `vf-cockpit-gouvernance.mjs` absent).
Autotest du lanceur : `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG0` → `Résultats : 5 PASS / 0 FAIL` (RG0.1 à RG0.5 verts, le lanceur naît dans cette tâche).

Motif commun : l'import du module échoue (fichier absent), la sonde `gv` rend une sortie vide, donc `obtenu: []` vide pour chaque témoin ; chaque mutant rougit sur « ancre » (fichier absent : `ancre absente`).

Bilan sur la base : `Résultats : 1 PASS / 29 FAIL`. Le seul vert est RG7.0 (fixtures : la ligne source `STALL_WINDOW="${VF_STALL_WINDOW:-900}"` est présente une fois dans le vrai script, les trois variantes sont posées), qui ne dépend pas du module.

| Identifiant | Assertion | Attendu | Obtenu sur la base |
|---|---|---|---|
| RG4.1 | phase non cochée, en-tête `human_needed` | `[{"phase":"73","ws":"w","cle":"w|73"}]` | vide (module absent) |
| RG4.2 / RG4.2b | phase cochée / archivée | `[]` | vide |
| RG4.3 | corps, en-tête sans statut, bloc non fermé, 2 Mio, au-delà de 40 lignes | `[0,0,0,1,0]` | vide |
| RG5.1 | aval(a), aval(c), inconnu | `[2,0,0]` | vide |
| RG5.2 | cycle, doublon, deps scalaire, `__proto__`, entrées hostiles, restants | `[1,0,0,1,0,0,0,0,0,2]` | vide |
| RG5.3 | détention listée / non listée / absente / ws hors grammaire | `[{"ws":"w","phase":"73"},null,null,null,{"ws":"w","phase":"73"}]` | vide |
| RG5.4 | impact retenu (mission 4, null, null, nœuds 2) | `[{"n":4,"portee":"mission"},null,null,{"n":2,"portee":"noeuds"}]` | vide |
| RG7.1 | vrai script du dépôt | `900` | vide |
| RG7.2 | variante au défaut 600 | `600` | vide |
| RG7.3 / RG7.3b | ligne retirée / commentée ou indentée | `null` | vide |
| RG7.4 | env 600, `abc`, `0`, `-5`, vide | `[600,900,900,900,900]` | vide |
| RG7.5 | `scriptGarde` | `["/check-guard-health.sh",null,null,null]` | vide |
| RG10.1 | turn_duration 3 en dernière ligne | `3` | vide |
| RG10.2 / RG10.3 | ligne assistant / autre sous-type system après | `0` | vide |
| RG10.4 | 0, -2, 1.5, 5000 | `[0,0,0,999]` | vide |
| RG10.5 | champ absent, fichier absent | `[0,0]` | vide |

Mutants (tâche 2) : voir la section ci-dessous une fois le module écrit.
