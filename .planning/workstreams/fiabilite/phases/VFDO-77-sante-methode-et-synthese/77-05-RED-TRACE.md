AVANT 5f15aebc75a4ef208d4d78f102e4266e127ed049

# 77-05 — trace des rouges

Suite : `plugin/cockpit/scripts/tests/test-cockpit-synthese-page.sh`, jouée avant tout code de `ui/74-vf-synthese.js`, sur la tête ci-dessus.
Invariants « inchangé » mesurés à ce commit : `plugin/cockpit/VERSION` = v1.4.0, `VERSION` racine = v2.76.0, blob de `ui/00-vibeflow.js` = 2c8693b2cc80, blob de `ui/20-health.js` = 9898b5af0493.
Résultat : 9 PASS / 29 FAIL en 192 s (deux serveurs lancés par `cockpit_lancer` sur une copie de module, chargée de façon prouvée, B4).
Les 9 verts sont les sondes du banc et les témoins statiques : CS1.0 (le glob ouvre des fichiers : les frères de 77-04), CS1.1, CS1.2, B1 à B5, H0.

## Rouges avec assertion, attendu, obtenu

Cause commune : le bouton n'existe pas (aucun `ui/74-vf-synthese.js`). Le scénario nomme son échec au premier point d'attente (« attente de « bouton Synthèse posé » dépassée (90000 ms) »),
sur les deux serveurs : aucune des mesures qui suivent n'a pu être prise, aucune ne vaut vert à vide.

- W2.1/W2.2 — `#btn-synthese` une fois sur Projet, juste après `#btn-health`, `aria-controls=panel`, `aria-expanded` faux, vrai, faux :
  attendu : `0,1,0|0|true` puis `true,panel,false,true,false,true` ; obtenu : `illisible` (la ligne JSON porte `{ erreur }`, B6 rouge avec elle).
- W11a.1 — aucun POST, aucune route de dernière commande ni de transcript, toute lecture de l'API porte le jeton :
  attendu : `0,0,0` ; obtenu : `illisible`.
- W13a.1 — focus sur le `h2` à l'ouverture, zone vive `status,polite,true` : attendu `Synthèse|-1|H2:true|status,polite,true` ; obtenu : `illisible`.
- O1 — aller-retour d'onglet : attendu `0,1,1,true,1,visite-burnup-methode,1,1,true` ; obtenu : `illisible`.
- RB1.1 — registre : attendu `visite-burnup-methode|true|true|visite=T-visite,burnup=T-burnup,methode=T-methode` ; obtenu : `illisible`.
- W18.2 — sans bloc témoin la ligne-résumé ne rend aucun nœud : attendu `0` ; obtenu : `illisible`.
