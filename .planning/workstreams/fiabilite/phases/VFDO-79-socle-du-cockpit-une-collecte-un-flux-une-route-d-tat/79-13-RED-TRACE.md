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

## Tâche 3 — rouges sur le code de la tâche 2 (suite jouée sur l'arbre du commit de la tâche 2 exporté, témoins de la tâche 3 seuls)
`bash <arbre exporté>/…/test-cockpit-frise.sh` : 83 PASS / 17 FAIL (23 s). Rouges :
- F0.4 : bloc `claudeCode.cibles` absent du contrat.
- F4.4 : un chemin à octet nul comptait comme une cible (« un fichier hors du lab ») : l'état était altéré par la ligne hostile (obtenu : deux entrées, attendu : `ok.js` seul).
- F4.7 : `cibles.tronque` jamais posé (obtenu faux là où 200 par sens sont dépassés).
- F4.11a, F4.11c, F4.11d, F4.11f, F4.11h, F4.11i : seul l'arbre principal était admis (worktree prouvé rendu « un fichier hors du lab », nom d'arbre jamais cherché).
- F4.13 : `fin` coupait à 120 sans marque ; F4.13b (serveur réel) : cible de 120 unités sans `…` (obtenu `…` faux).
- F6.6 : worktree prouvé rendu `{ arbre: null, cible: wt-in/src/b.js }` au lieu de `{ arbre: wt-in, cible: src/b.js }`.
- Mutants dont l'ancre n'existait pas : M-ARBRE, M-COLLISION, M-PRINCIPAL, M-ELLIPSE, M-TRONQUE-CIBLES.
- Verts d'emblée (modules de la tâche 1 déjà tenus, chacun prouvé ensuite par son mutant) : F4.1, F4.2, F4.3, F4.5, F4.6, F4.8, F4.9 (la passe découpée par budget converge), F4.10.
- Corrections de harnais avant le code : l'oracle de F4.1 résolvait `..` lexicalement (realpath non natif) : passé à `realpath.native` ; couverture de F4.5 rendue déterministe.
- `test-cockpit-transcript.sh` sur le code présent : T24H1 à T24H3, T24H5, T24H7, T24H8 rouges (forme écrite, pas de worktree, coupe sans marque) ; T24G2 réécrite : le témoin positif de l'ancienne mesure (espion sur `fs.realpathSync`) était aveugle après 79-07 ; nouvelle mesure sur `fs.realpathSync.native`.

## Tâche 3 — vert et mutants
`test-cockpit-frise.sh` : 105 PASS / 0 FAIL (25 s), graine jouée imprimée (propriétés F4.1, F4.2, F4.5, F4.6, F4.13).
Mutants de la tâche (ancre, substitution, `cmp` par `.0`, identifiant rouge) : M-LEXICAL, M-ECHEC-OUVERT, M-PARENT, M-PREFIXE -> F4.1 ; M-OUTILS -> F4.3 ; M-CURSEUR -> F4.5 ;
M-TRANCHE -> F4.9 (reste faux dès la première tranche) ; M-PERSISTE -> F4.10 ; M-ARBRE -> F4.11d ; M-VERIF (copie de `vf-cockpit-arbres.mjs`, `worktreeVerifie` neutralisé) -> F4.11f ;
M-COLLISION -> F4.11h ; M-PRINCIPAL -> F4.11i ; M-ELLIPSE -> F4.13 ; M-TRONQUE-CIBLES -> F4.7. Les quatorze rougissent pour la raison nommée (vingt-cinq au total avec la tâche 2).
`test-cockpit-transcript.sh` : 111 PASS / 0 FAIL. T24G2 : un outil seul = 6 appels réels au noyau (table des arbres comprise) ; 200 outils gardés : 404 appels, borne 6 x 200 + 10 = 1210.
Avant la reprise (79-07) la mesure comptait au plus 410 appels de `fs.realpathSync` ; l'ancienne mesure serait restée à 0 après la reprise (aveugle).
Suites existantes adaptées : `test-cockpit-transcript.sh` (copie complète des modules dans le mutant de regroupement ; ancre de T24F3.3 sur la ligne de retour d'`etiquette`).
Régression de la tâche 3 : who 157/0, equipe 215/0, equipe-etats 86/0, lecture-fil 17/0, git-config-depot 138/0, git-env 135/0, collecte 149/0 (323 s), vendor : V4 « check-file-size » rouge au moment du
rejeu (base : fichier du module à 300 lignes qui n'est pas à moi, signalé par le manager) ; V4c.9a (cliquet de colonnes) rouge sur ma HAUSSE de 13 à 15 lignes longues de `vf-cockpit-transcript.mjs`,
corrigée dans le commit (retour à 13, `colonnes-cliquet.mjs verifier` : OK, baseline inchangée).

## Tâche 4 — rouges sur le code de la tâche 3 (suite complète jouée sur l'arbre du commit de la tâche 3 exporté, `brancherFluxFrise` et `finDeTour` en coquilles vides)
123 PASS / 10 FAIL (3 min) : F5.1 (aucun événement frise à la fin du tour), F5.3, F5.4, F5.9, F5.6b (aucun événement après la ligne ajoutée), F5.6c, F5.6d (aucun événement au passage actif -> attend),
F5.8 (aucun événement pendant la passe), M-EMET-PAQUET.0 (ancre `garde:frise-pose` absente), M-SIG-AT (rouge parce qu'aucun événement n'existe : la raison du flip n'était pas encore atteignable).
Verts d'emblée (garde-fous prouvés ensuite par leurs mutants ou leurs témoins positifs) : F5.2, F5.5 (module de signature présent), F5.6a, F5.7, F6.1 à F6.6.

## Tâche 4 — vert, mutants, mesures
`test-cockpit-frise.sh` : 135 PASS / 0 FAIL (environ 170 s), graine imprimée (F2.2, F4.1, F4.5, F4.6, F4.13, F5.5), 30 mutants (60 assertions `M-`).
Mutants de la tâche : M-SIG-CIBLES -> F5.5 et F5.3 ; M-SIG-AT -> F5.2 ; M-SIG-ORDRE -> F5.5 ; M-EMET-PAQUET -> F5.1 et F5.9.
Mesures (serveur B, fixture de 6 voies de 4 000 appels d'outil) : sonde de latence pendant le démarrage et la passe : n=78, p50 1 ms, p99 5 ms, max 5 ms, pics 5, 3, 2, 2, 2, zéro erreur ;
même sonde sur le collecteur en ligne (étapes sur la boucle) : p99 et max 463 ms (547 ms à une autre exécution), pics 463, 366, 265, 162, 153 : la sonde sait rougir.
Taille : 2 400 entrées de cible, 178 273 octets de réponse, durées de `GET /api/vf/frise` : 40, 43, 43, 44, 40 ms (médiane 43 ms) ; un événement `frise` pendant la passe.
Serveur A : fenêtre calme de 12 s sans événement ; une ligne ajoutée : un événement ; `etat` actif -> attend : un événement ; segment de queue `attend-humain` commençant à `fin` puis retiré au retour à actif.
Suites existantes rejouées sur la tête (T4) : routes 56/0, serveur 98/0, securite 103/0, etat 127/0 (494 s), direct 76/0, cycle-serveur rc 0, lancer-serveur 82/0, robustesse 25/0,
git-signature 47/0, reseau 15/0, signal 76/0 ; vendor : un seul rouge, V4 `check-file-size` (base : fichier du module à 300 lignes qui n'est pas à moi) ; le cliquet de colonnes (V4c.9a) est vert.
