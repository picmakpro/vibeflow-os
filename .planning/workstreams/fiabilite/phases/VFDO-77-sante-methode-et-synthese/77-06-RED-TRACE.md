AVANT a703f6f972d6137a94d28c123c57a13ec777e527
plugin/cockpit/VERSION : v1.4.0 (inchangée) ; empreinte de la coquille `ui/74-vf-synthese.js` (git hash-object) : c599e899022f794ca4ff4bafca112d2567384595

# 77-06 — traces rouges (régime allégé : le témoin d'abord, vu rouge ; pas de mutant hors M-INNERHTML)

Suite `test-cockpit-synthese-blocs.sh` jouée sur le module SANS les deux fichiers neufs : 2 PASS / 57 FAIL en 52 s (les deux PASS sont les témoins de préparation B1 et de fin H0 : le lab daté, la copie
du module et les faux gates sont posés, aucun processus ne survit).

| Assertion | Attendu | Obtenu |
|---|---|---|
| BG2.1 courbe, jalon en cours (aujourd'hui 9 nov.) | `{"clos":"M28 128H28V128H80V100H132V72H236","perimetre":"M28 44H80V44H132V16H236"}` | `undefined` (le fichier n'existe pas) |
| W8.1 tête = pied du jalon | `2\|5\|40\|2\|40` | `illisible:/2 clos · 0 à recetter · 3 à faire · 40 %` (pas de tête ; le pied du jalon est bien lu : 2 clos, 40 %) |
| W8.10 marches de la série des clôtures | `2\|1` | `erreur:Cannot read properties of undefined (reading 'd')` (aucune série) |
| W9.1 onze jauges au vocabulaire fermé | `11\|true\|state,…,socle\|Planning/Mémoire et chantiers/Instructions des agents\|3` | `0\|true\|\|\|0` |
| JA1 aucune lecture avant l'ouverture, une à l'ouverture | `0\|true\|1\|1` | `0\|true\|0\|0` (la sonde positive voit les GET existants ; la route n'est jamais lue) |

Sondes positives posées d'abord (vues vertes dans la même suite) : le journal réseau voit des `GET /api/vf/` avec jeton ; l'audit de couleur voit une teinte injectée (W4b, `sondeAudit`) ; le compteur
d'écouteurs de média voit un écouteur posé puis retiré (BO1, `sondeMQ`) ; le faux gate « tout dans le budget » donne des barres (JA5.b).
