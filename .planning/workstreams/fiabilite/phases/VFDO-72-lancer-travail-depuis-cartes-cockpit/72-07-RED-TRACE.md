# 72-07 — Trace du rouge (suivi des lancements, LANC-10)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-suivi.sh` (HEAD b93fb088, sans `vf-cockpit-lancer-suivi.mjs`, `vf-cockpit-equipe-carte.mjs` d'avant le plan).
sha256 de la copie figée (module d'avant, relevé par `git show HEAD:plugin/cockpit/scripts/vf-cockpit-equipe-carte.mjs | shasum -a 256`) : `cd40e07b3202a10a122c929c892d2459278efec2f3ba145941d0b9b68aa46f47`.
Résumé : rc=1, 4 PASS / 33 FAIL. Verts sur la base, comme prévu : LE.0 (copie fidèle), LE.1 (63 comparaisons identiques), LE.6 (aucun nom de session lu), hygiène H0.

## Familles

| Sonde | attendu | obtenu (base) |
|-------|---------|---------------|
| LS1.1 à LS1.4 | noter : `{"ok":true}\|1`, 8 refus « forme », contexte hostile à nuls, `deja`, 200 entrées | `ABSENT` (module du suivi absent) |
| LS2.1 | `false,true,true,false,false` | `ABSENT` |
| LS2.2 | `true,true,true/true` | `ABSENT` |
| LS3.1 à LS3.7 | `attendue…`, `vue,vue`, `terminee`, `attendue,attendue,attendue,vue`, `0,false,0\|vue,terminee,vue`, `1,0,0`, `86400000\|86400000\|true` | `ABSENT` |
| LS4.1 à LS4.4 | clés exactes, aucune clé interdite, module sans import, constantes | `ABSENT` |
| LE.2 | `details:ok\|reste:ok` | `details:ko\|reste:ok` (la ligne manque : le paramètre est ignoré) |
| LE.3 | `details:ok\|reste:ok` | `details:ko\|reste:ok` |
| LE.4 | `exc:0\|reste:ok\|temoin:ok\|hostile:aucune` | `exc:0\|reste:ok\|temoin:ko\|hostile:aucune` (le témoin positif manque) |
| LE.5 | `diff:se-2222…\|noeuds:true\|ligne:ok` | `diff:\|noeuds:true\|ligne:ko` |

Écart au plan notée : LS2.2 joue `at:5` (en plus de `at:0`) : avec `at:0`, `Number(0) \|\| maintenant()` vaut `maintenant()`, le mutant M-AT-DU-MESSAGE serait resté vivant.

## Mutants (sur la base)

Les onze sont « mutant sans effet : cible absente ou module d'avant » : M-FORME-LIBRE, M-AT-DU-MESSAGE, M-SANS-BORNE, M-RECENCE-INFINIE, M-ATTENTE-ILLIMITEE, M-TTL-IGNORE, M-RATTACHE-PAR-NOM, M-TERMINEE-PERDUE (module du suivi absent), M-LANCEES-HORS-SESSION, M-LIGNE-SANS-VALIDATION, M-LIGNE-VIDE-TOUJOURS (marqueur de garde absent de la carte d'avant).
