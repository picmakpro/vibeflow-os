AVANT=6f104e1a6459a93d937f0ae1e33433e8c75a4da2

# 79-13 — trace des rouges (régime allégé)

## Mesures de base (avant tout code)
- `vf-cockpit-server.mjs` 204 lignes ; `-instantane` 38 ; `-collecte` 179 ; `-collecte-fil` 32 ; `-collecte-etapes` 54 ; `-transcript` 120.
- Décomptes : ligne quotée de la route de frise dans le serveur 0 ; schéma de frise au contrat 0 ; modules neufs absents ; `function cheminDuLab` dans le transcript 1.
- N (suites du gate) = 226 avant ; 227 après `test-cockpit-frise.sh`.
- Hypothèses : H1 confirmée (`etapeTour`, `memo.index`, fil à messages `tour`/`index`/`fini`) ; H2 confirmée (`poser` gelait par un `WeakSet` privé) ;
  H3 : `rattacherVoies(voies, travailleurs)` rend une `Map` id -> rattachement (lue telle quelle) ; H4 confirmée (`publique`, `enumerer`, `bilan`, arbre persisté) ;
  H5 confirmée ; H6 confirmée (`creerSignaleur`) ; H7 confirmée ; H8 confirmée.

## Tâche 1 — rouges sur le code présent (suite écrite seule, `test-cockpit-frise.sh`)
- F0.1, F0.2, F0.3 : modules absents, chemin absent de `ROUTES`, schéma absent du contrat.
- F1.1, F1.2, F1.3, F1.5 : 404 sur `GET /api/vf/frise` (corps vide).
- F1.0, F1.0a (serveur voit la voie), F1.4 (vide) verts d'emblée ; F1.4 durcie ensuite (exige une voie servie) pour ne pas être verte à vide.
- RK.1 / RK.7 de `test-cockpit-routes.sh` : RK.7 compte les routes en littéral (7) : passé à 8.
- D8.9 de `test-cockpit-lecture-fil.sh` : un schéma de plus interdit `fil` (liste fermée réarmée avec `cockpit-frise@1`).

## Tâche 1 — vert
- `test-cockpit-frise.sh` : 11 PASS / 0 FAIL (3 s) ; `routes` 56/0 ; `serveur` 98/0.
