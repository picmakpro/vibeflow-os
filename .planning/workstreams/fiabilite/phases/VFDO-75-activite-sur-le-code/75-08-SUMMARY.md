# 75-08 — SUMMARY : le sélecteur de lentilles, le menu, le panneau et le radar (ACTV-01, ACTV-02, ACTV-06, ACTV-07, ACTV-08, ACTV-10)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Exception tenue : la chaîne XSS (deux mutants vus rouges).

## Livré

- `ui/75-vf-activite.js` (167 lignes) : le moteur de la phase côté page, initialisé par `VF_COQUILLE.surOnglet` (cle = nom du fichier) quand l'onglet vaut Code, retiré entièrement en le quittant. Bouton `#btn-lentilles` posé juste après Santé
  (carré, `.bl` « Lentille : Aucune », `aria-haspopup`, sans `aria-pressed`, infobulle exacte, pastille neutre `--on`), lecture de `GET /api/vf/activite` par `VF_ETAT.lireJson` à `frise`, `git`, `planning`, connexion rétablie, puis une fois par
  seconde au plus 15 fois tant que `calcul` vaut `en-cours` ; marques par le canal figé `VF_MARQUES` (couches `activite` exclusive et `activite-collisions` non exclusive) ; rien n'est mémorisé. Il tient le point de rencontre `window.VF_ACTIVITE.brancher(nom, fabrique)`.
- `ui/75-vf-activite-tables.js` (249 lignes) : fonctions pures (tables de marques des quatre lentilles, états, modèle du menu, phrases, annonces) ; `ui/75-vf-activite-menu.js` (139) : `#lens-menu` (role=menu sur le seul conteneur des rangées, légende et radar hors du menu,
  clavier, pile de surcouches, exclusion avec `#legend` et `#flowmenu`) ; `ui/75-vf-activite-panneau.js` (139) : sections « Points chauds », « Change souvent avec », « Gardes », « Agents sur ce fichier », « Collisions possibles » ;
  `ui/75-vf-activite-collisions.js` (106) : le compte du radar dans `.k`, annonce unique, ouverture du panneau. Chaque fichier s'inscrit par `surOnglet` avec sa `cle` et rend son nettoyage.
- `viewer.html` : `#lens-menu` avec `#legend` et `#flowmenu` (position, plafond de hauteur) ; `02-vf-telephone.js` : `#btn-lentilles` ajouté à la règle qui masque les boutons d'en-tête à 999 px et moins (l'entrée du « ⋯ » vient du bouton, le fichier n'a pas d'autre ligne) ;
  `VENDORED.txt` : cinq lignes `AJOUT`, dans l'ordre d'octets.
- `test-cockpit-activite-lentilles.sh` (L0 à L22, 110 PASS, 2 `MUTANT-ROUGE`), `chrome-activite-lentilles.mjs`, aides sous `fixtures/test-cockpit-activite-lentilles/` (lab avec historique git et nom de fichier hostile, données de route poussées par la page, harnais `vm`, mesures t1 à t3), `75-08-RED-TRACE.md`.

## Écarts

- Écart : TDD en trois commits mais le code des trois tâches a été écrit en un jet (mêmes fichiers) : le rouge de la tâche 1 est celui de la base `95f9b75a` ; ceux des tâches 2 et 3 sont rouges sur la base et sur des copies mutées (voir la trace). Mutants levés par le régime allégé, sauf XSS.
- Écart : l'étiquette `.bl` du bouton est masquée à tout gabarit (aux 1 600 px et plus, les autres boutons montrent la leur : visible, elle élargirait l'en-tête à chaque choix de lentille) ; elle reste dans le DOM, lue par le « ⋯ ». L'état actif se voit par un disque central dans la lentille (r = 3 contre 0), pas par le libellé : choix de L20.
- Écart : le bouton est un `btn icon` (36 px) : à 1 024 px l'en-tête n'a pas la place d'un bouton à étiquette (bouton de 42 px).
- Écart : « sans glyphe » (« nommé par n suites » ; la carte sélectionnée du couplage) se rend avec le glyphe neutre du canal (carré creux `--text-3`) : l'API figée de `VF_MARQUES` n'a pas d'option pour poser une marque sans glyphe (clé inconnue = glyphe neutre, 75-07). Et l'agrégat de nœud du canal est toujours posé : « n fichiers » sur une carte de nœud sous Couplage, là où la spec n'en veut aucun.
- Écart : la route ne sert que le NOMBRE de suites qui nomment un fichier (`gardes[i][1]`), jamais leurs noms : la section Gardes dit « Nommé par : 2 suites » (la spec : jusqu'à 5 suites en mono), l'infobulle ne liste pas les trois premières (75-05).
- Écart : le palier de Points chauds est dit par le texte par un observateur de `aria-label` (le canal réécrit le nom à chaque passage) : « 12 changements, palier haut » ; le rang vit dans une section « Points chauds » du panneau que la spec § 4 ne liste pas.
- Écart : le panneau s'ouvre depuis le compte sans `setPanel` (qui rappelle `fit()` et pousserait la carte, Q12) ; sélection sans collision : panneau personnalisé « Base de code » avec la section du dépôt entier. Sans sélection dans un dossier, la section « Collisions possibles » liste les fichiers de ce dossier (le compte, lui, vaut pour le dépôt).
- Écart : un radar incomplet dit sa phrase (« Radar en cours de relecture », « Radar incomplet : … ») même quand des collisions sont déjà connues ; « Radar incomplet » seul pour une raison que la spec ne nomme pas ; palier 1 de la route (moins de 12 fichiers) lu « bas ».
- Écart : le « ⋯ » à 999 px et moins n'a pas reçu `Home`, `Fin`, `Espace` : le menu des lentilles porte son propre clavier ; `02-vf-telephone.js` n'a que la ligne du sélecteur.
- Écart : une lentille active qui devient indisponible est annoncée (« Lentille Points chauds indisponible. ») au passage, pas au choix (une ligne désactivée ne se choisit pas).
- Limite : espaces de noms neufs sur `window` (`VF_ACTIVITE`, `VF_ACTIVITE_TABLES`), jamais `window.VibeFlow` ; ils s'en vont avec l'onglet.
- Limite : sous charge forte (quatre suites Chrome en parallèle sur le poste) un mutant de la suite de la carte a rougi une fois sans reproduction au rejeu (D4) ; le bloc R13 de `test-cockpit-responsive.sh` est long (plus de dix minutes) mais est allé au bout.

## Suites jouées (têtes commitées, code identique à `f006c1ee`)

- `test-cockpit-activite-lentilles.sh` : vert, 110 PASS, 0 FAIL, 2 MUTANT-ROUGE (182 s). `test-cockpit-vendor.sh` : vert, 253 PASS, 0 FAIL (261 s sous charge). `scripts/check-machine-paths.sh` : vert ; cliquet de colonnes : OK, aucun de mes fichiers en écart.
- `test-cockpit-activite-carte.sh` (75-07, 118 s) : ROUGE, 66 PASS / 1 FAIL à D11 (lod-mid). Cause : la couche de collisions de 75-08 pose, d'après la route réelle, « prévu par 2 plans, vague 1 » (le lab de cette suite a deux plans sur `src/a/neuf.mjs`) ; D11 lit le premier `.lm` de la carte
  `d:d-src|src/a`, devenu l'agrégat de collision compact. Dans une copie de la suite où `charger` retire la couche (`await s.ev("VF_MARQUES.retirer('activite-collisions')")` avant `return poser();`, `chrome-activite-carte.mjs`) : 91 PASS, 0 FAIL. D14b rougit aussi sans cela (la prévue gagne un mot de collision dans son nom). Hors de mes fichiers : à poser côté 75-07.
- `test-cockpit-responsive.sh` (1 027 s ; un premier jeu, 818 s, donnait le même verdict ; aucune mort silencieuse au bloc R13) : ROUGE, 370 PASS / 9 FAIL : R1 et R2 (labs court et long), R8 (deux), R9, D39.6 à 1 024 px sur l'onglet Code (#btn-panel de 990 à 1 026 sur 1 024), et R13.3. Cause : la suite injecte l'ancien
  bouton de récent et celui des écrans pour mesurer « le pire en-tête réel » ; le sélecteur est un bouton de plus tant que l'ancien existe (2 px de trop). Simulation sur une copie de la suite qui n'injecte plus l'ancien bouton (l'état d'après 75-09b) : 378 PASS / 1 FAIL, R13.3 seul. R13.3 attend la liste exacte des entrées du « ⋯ » : à migrer par 75-09b
  (« Lentille : Aucune » à la place de « Travail récent » ; références `test-cockpit-responsive.sh:90` et `:496` du plan).
- Temps dans les suites : lentilles 182 s, vendor 261 s, carte 118 s (et 178 s au jeu précédent), responsive 1 027 s, simulation responsive 1 039 s ; environ vingt passes de la suite de la tâche pendant la mise au point (30 à 55 s chacune).

## Contrats que d'autres plans consomment

- `VF_MARQUES` (75-07, figée ; Phase 74 s'écrit dessus) : il manque deux choses pour la spec, que je n'ai pas contournées : une marque SANS glyphe (rangée `glyphe` vide ou option) et la suppression de l'agrégat de nœud d'une couche (Couplage n'en veut aucun). À trancher avec 75-07 et 74-06.
- `GET /api/vf/activite` (75-05) : `gardes[i][1]` est un nombre ; la spec montre jusqu'à cinq noms de suites par fichier (panneau et infobulle). À servir (noms plafonnés) pour compléter la section « Gardes ».
- Couche `activite-collisions` (nom posé ici, non exclusive) : à retirer au début des témoins qui mesurent la carte avec des collisions posées à la main (`test-cockpit-activite-carte.sh`, voir ci-dessus).
- Retrait de l'ancien bouton (75-09a à 75-09c) : aucun fichier de ce plan ne cite son identifiant (`grep` vide) ; le sélecteur et l'ancien bouton coexistent ; `test-cockpit-responsive.sh` : injection de l'ancien bouton, liste de R13.3 et références `#btn-recent` à migrer vers `#btn-lentilles` (`.bl` « Lentille : Aucune »).
- Non écrit, au manager : ROADMAP, STATE, REQUIREMENTS ; CHANGELOG du module (« cockpit : sélecteur de lentilles d'activité sur le code, avec son menu, ses sections de panneau et le compte du radar dans la rangée de contexte ; l'ancien bouton est retiré par 75-09 ») ;
  `ci-shard-suites.sh` : `test-cockpit-activite-lentilles.sh` (environ 3 minutes) ; compteur « N suites » des README (`check-version-sync.sh`) : une suite de plus ; DESIGN.md § 12 (amendements prévus par la spec).
- Écarts avec 75-UI-SPEC à corriger côté spec : « pastille `--recent` en bureau » (la pastille est neutre, P75-D-27 prime) ; pas d'`aria-pressed` ; `role="menu"` sur les seules rangées ; unité du radar : le fichier ; `.bl` masqué à tout gabarit ; disque central pour l'état actif ; section « Points chauds » du panneau (rang) ; « sans glyphe » rendu par le glyphe neutre.
