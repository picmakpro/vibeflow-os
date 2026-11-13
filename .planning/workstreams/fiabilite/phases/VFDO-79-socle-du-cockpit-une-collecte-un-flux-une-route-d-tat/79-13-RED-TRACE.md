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

## Tâche 2 — rouges sur le code de la tâche 1 (suite jouée sur l'arbre du commit ba48dbd0, témoins de la tâche 2 seuls)
Commande : `bash <arbre exporté>/plugin/cockpit/scripts/tests/test-cockpit-frise.sh` (35 PASS / 15 FAIL, 9 s).
- F2.2 (propriété des paramètres, graine 3102) : attendu `0|true|corps` ; obtenu : la route n'a aucune validation (200 partout).
- F2.4 (fenêtre) : `depuis` de 48 h non ramené, `depuis >= jusqua` non refusé. F2.5 (champs) : `champs` ignoré, 200 au lieu de 400.
- F2.8 (source) : `source.etat` jamais `indisponible` (le direct n'est pas lu). F2.11 (fenêtre fine) : segments non coupés.
- F2.12 (ordre et inclusion), F2.13 (queue d'attente), F2.15 (500 voies, `voiesOmises`) : absents. F2.3 : couverture rouge faute de l'oracle servi.
- F3.7 (fusion) : rouge de harnais (un `entries()` mal déstructuré dans le témoin, corrigé avant le code).
- Verts d'emblée (tenus par la réponse gardée de 79-05 et la liste blanche de la tâche 1) : F2.1, F2.6, F2.7, F2.9, F2.10, F2.14, F3.1 à F3.6.
- Mutants dont l'ancre n'existait pas encore : M-BORNES, M-FENETRE, M-ATTEND, M-BORNE-REPONSE, M-OMISES (suffixe `.0` rouge sur le code de la tâche 1).

## Tâche 2 — vert et mutants
`test-cockpit-frise.sh` : 55 PASS / 0 FAIL (11 s), graine jouée imprimée. Mutants (ancre, substitution `sed`, `cmp` prouvé par le `.0`, identifiant rouge) :
M-LISTE-BLANCHE -> F3.1 ; M-BORNES -> F2.2 ; M-FENETRE -> F2.4 ; M-REVEIL -> F2.7 ; M-GARDE -> F2.6 ; M-ATTEND -> F2.13 ; M-OFFICIEL -> F3.2 ;
M-RATTACHEMENT -> F3.3 ; M-BORNE-INSTANTANE -> F3.5 ; M-BORNE-REPONSE -> F2.15 ; M-OMISES -> F2.15. Les onze rougissent pour la raison nommée.
Suites rejouées : routes 56/0, serveur 98/0, securite 103/0.
