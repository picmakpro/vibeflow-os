# 70-07 — trace rouge / vert (P70-D-08, méthode allégée selon le risque)

## Rouge — code d'avant le patch de `40-tour.js` (tête ca05484f)

Date : 2026-11-04. Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` (lab jetable de 3 dossiers à cartes de premier niveau, servi par le vrai lanceur, onglet Code, 3 étapes à chaque largeur).
Résultat : 61 PASS / 6 FAIL ; aucune autre suite touchée, O4 non sautée, O5.0, O5.4 et O5.5 verts (témoin posé ; repère et français déjà bons depuis 70-03).

- FAIL — O5.1 [1440 px] : attendu `[]` ; obtenu `[1,2,3]` (étape 1 sans cible ; étapes 2 et 3 : carte sélectionnée mais ni centrée ni zoomée).
- FAIL — O5.2 [1440 px] : attendu `[]` ; obtenu `[1,2,3]` (résumé de plus de 230 caractères coupé à la première phrase : la fin « FINDETEXTE » n'est pas dans le texte).
- FAIL — O5.3 [1440 px] : attendu `[]` ; obtenu `[2,3]` (« Passer » n'existe qu'à l'étape 1 ; ailleurs, seule une icône « Retour »).
- FAIL — O5.1 [390 px] : attendu `[]` ; obtenu `[1,2,3]`.
- FAIL — O5.2 [390 px] : attendu `[]` ; obtenu `[1,2,3]`.
- FAIL — O5.3 [390 px] : attendu `[]` ; obtenu `[2,3]`.

## Vert — après le patch P25 (commits fix(70-07))

`test-cockpit-projet.sh` 67 PASS / 0 FAIL (O5.0 à O5.5 aux deux largeurs). Premier rejeu : O5.5 [390 px] rouge à l'étape 3 (obtenu `[3]`, mot « Start ») : le texte de la dernière étape, sur téléphone, cite « ⋯ › Start here » ; entrée ajoutée à `79-vf-fr-dict-b.js`, puis vert.
`test-cockpit-vendor.sh` 79/0 (V6 : amont retrouvé à l'octet, V7 : diff présent) · `test-cockpit-chrome-fr.sh` 59/0 · `test-cockpit-onglet-code.sh` 21/0 · `test-cockpit-marque-blanche.sh` et `test-cockpit-assemblage.sh` exit 0.
`test-cockpit-responsive.sh` non rejoué ici (consigne du mandat : le manager le rejoue à l'intégration) ; la carte de visite a changé de structure (colonne flex, hauteur bornée, contour `.tour-target`), c'est la surface à surveiller.

## Suite : rechargement (correctif ciblé demandé par le manager, écart relevé par 70-08)

### Rouge — tête 34b58f61 + témoins O6.9 et O5.6

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` — 89 PASS / 3 FAIL, tous dans O6.9 ; O6.5 (Chrome neuf par largeur) gardé, vert. La sonde mesure chaque largeur deux fois dans le même profil (option `recharge`).

- FAIL — O6.9 [r390] : attendu `[]` ; obtenu `[1]` (étape 1 de la visite Projet, une carte, mal centrée au rechargement).
- FAIL — O6.9 [l1440] : attendu `[]` ; obtenu `[1]` (page déjà chargée à 390 px dans le même profil).
- FAIL — O6.9 [r1440] : attendu `[]` ; obtenu `[1]`.
- O6.9 [l390] (premier chargement du profil) vert : c'est le seul cas que O6.5 mesurait.
- O5.6 (onglet Code, 1 440 et 390 px, rechargé) vert avant correction : la première étape y est la racine (`#context`), pas une carte.

### Cause et vert

Cause : à l'ouverture, `show(0)` programmait toujours `SC.fit(true)` à 450 ms. Quand la première étape est une carte (onglet Projet, 70-08), le centrage de la carte (mesuré à 60 ms si la carte est déjà posée) était défait par ce fit ; sur un profil neuf la page se pose plus lentement, la carte était mesurée à 650 ms, après le fit, et le cas était masqué. Correctif : le fit d'ouverture ne se programme que si la première étape est la vue d'ensemble (`ref` racine). Patch P25 mis à jour (`assets__ui__40-tour.js.diff`, ligne de `VENDORED.txt`).

Vert : `test-cockpit-projet.sh` 92 PASS / 0 FAIL (O6.9 aux quatre passes, O5.6 Code à 1 440 et 390 px, O6.5 conservé) ; `test-cockpit-vendor.sh` et `test-cockpit-chrome-fr.sh` 79 PASS / 0 FAIL et 59 PASS / 0 FAIL ; `synchro.sh verifier` : amont retrouvé à l'octet.

## Suite : grandes cartes (REG-70-01 de `70-VERIFICATION.md`)

### Rouge — tête 779bee45 + témoin O6.10

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` — 93 PASS / 2 FAIL, les deux dans O6.10 (lab à jalon et à mission, nom long, visite Projet active au premier chargement ; sonde `chrome-visite-etapes.mjs`, champs `dansZone` et `toutLibre`, ce dernier reprenant le critère de R1).

- FAIL — O6.10 [1024 px] : attendu `[]` ; obtenu `[1]` (étape 1, la carte du jalon : une carte du graphe sort de la zone libre à gauche du panneau).
- FAIL — O6.10 [1920 px] : attendu `[]` ; obtenu `[1]`.

Mécanisme mesuré : `aim()` centre et zoome sur la carte ciblée sans regarder le reste du graphe, qui déborde alors sous le panneau (R1 mesure l'union de toutes les cartes) ; il ne dézoome jamais, donc une carte plus large que sa zone y déborde aussi.

## Suite : « Passer » et contour (juge Playwright de la recette)

### Rouge — arbre de la correction O6.10 (centrage borné, sans sélection) + témoins O6.11 et O6.12

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` — 95 PASS / 5 FAIL. H0 rougit par un Chrome d'une autre suite lancée en même temps dans un autre worktree (bruit de concurrence, absent d'un rejeu isolé).

- FAIL — O6.11 [1440 px] : attendu `[true]` ; obtenu `[false]` (lab à quatorze phases : avant la visite k 1,1, x 106, y 244, 4 cartes dans la fenêtre ; après « Passer » à l'étape 3 : k 1,1, x 315, y 296, 1 carte).
- FAIL — O6.11 [390 px] : attendu `[true]` ; obtenu `[false]` (avant k 0,448, x 25, y 326, 4 cartes ; après k 0,852, x 33, y 260, 1 carte).
- FAIL — O6.12 [1440 px] : attendu `[]` ; obtenu `[4]` (le contour de l'étape « au travail » disparaît quand le className de `#vf-lock` est réécrit, comme le fait `70-vf-live.js`).
- FAIL — O6.12 [390 px] : attendu `[]` ; obtenu `[4]`.

### Causes et vert (grandes cartes, « Passer », contour)

- REG-70-01 : `aim()` centrait et zoomait sans regarder le reste du graphe. Il borne maintenant le zoom pour que toutes les cartes restent dans la zone libre, dézoome une carte plus large que sa zone, et recentre au plus près du milieu de la zone sans sortir une autre carte (le centrage reste dans le tiers central, ou aussi central que le permet le graphe : la sonde le dit, `centre`). R5.3 rougissait pour une autre raison : la visite sélectionnait la carte, donc le panneau montrait son détail au lieu de la vue d'ensemble ; la visite n'en sélectionne plus, elle l'éclaire avec la mise en évidence du viewer (`hl` sur la carte, `dim` sur le reste). Témoin O6.10 (carte dans la zone libre, aucune carte hors zone libre, aucune sélection) rouge sur 779bee45 (étape 1 aux deux largeurs), vert après.
- « Passer » : l'étape sur une carte d'un groupe ouvre ce groupe (`go(parent)`) ; `end()` ne rendait la vue d'ensemble que depuis la racine. Toute sortie (Passer, croix, Échap, Terminé) revient maintenant à la racine et ajuste (`go('root')` puis `fit`), sauf le lancement d'un parcours guidé, qui reprend la main.
- Contour : posé sur la cible par un élément propre (`.tour-target`, `position: fixed`), retrouvé par son sélecteur toutes les 250 ms : il ne dépend plus du `className` de la cible, que `70-vf-live.js` réécrit. `70-vf-live.js` n'a pas été touché.
- Vert : `test-cockpit-projet.sh` 100 PASS / 0 FAIL (O6.10, O6.11, O6.12 aux largeurs mesurées) ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 70/0 ; `test-cockpit-responsive.sh` 255 PASS / 6 FAIL, les six R13.4 connus seuls (R1, R5.3 et R9 verts) ; `synchro.sh verifier` : amont retrouvé à l'octet.

## Suite : CI Linux (PR #200, 0ffd3e82, shard 6)

Constat CI : `R20 — Équipe / 768 px` rouge sous Linux seulement, attendu `[aucune]`, obtenu `[surfaces : #panel recouvre #tour | en-tête et surfaces : #panel recouvre #tour]`.

**Non reproduit par l'émulation de pointeur.** `CHROME_BIN` pointé sur un Chrome lancé avec `--blink-settings=primaryPointerType=1,availablePointerTypes=1,primaryHoverType=1,availableHoverTypes=1` (le procédé de R8 : `pointer: none`) : `test-cockpit-responsive.sh` 255 PASS / 6 FAIL, R20 vert aux quatre largeurs. Le pointeur n'est donc pas la cause. Sur Équipe, le lab local n'ouvre pas la visite (moins de deux cartes) ; mesure à 768 px sur Projet, avec ou sans pointeur : carte de visite 16..376, panneau 392..752, pas de recouvrement.

**Cause retenue (non observée sous Linux, déduite de la géométrie).** À 768 px, la carte de visite fait 360 px de large à gauche et le panneau commence à 392 px : 16 px de marge. Toute largeur de panneau plus grande d'une quinzaine de pixels (polices et plateforme la font varier) le fait passer sous la carte. La carte ne regardait pas le panneau.

### Rouge — 0ffd3e82, sonde `chrome-visite-etapes.mjs` option `panneau` (panneau élargi à 440 px, ce qui rougit sans Linux)

768 px, lab Projet : `surPanneau` = `[true,true,true,true]` aux quatre étapes ; 1 024 px : `[false,…]` (le panneau y est à droite de la carte avec de la marge). Témoin O6.13 de `test-cockpit-projet.sh`, mêmes mesures : rouge à 768 px (étapes `1,2,3,4`), vert à 1 024 px.

### Correction et vert

`place()` rétrécit la carte de visite (au plus jusqu'à 12 px du panneau, 200 px au minimum) quand elle recouvrirait un panneau latéral, et ne la fait plus passer de l'autre côté (étape sur un élément du chrome) si ce côté recouvre le panneau. Après : `surPanneau` faux à toutes les étapes, aux deux largeurs. `test-cockpit-projet.sh` 103 PASS / 0 FAIL (O6.13 incluse) ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 70/0 ; `test-cockpit-responsive.sh` 255 PASS / 6 FAIL (les six R13.4 seuls) ; `synchro.sh verifier` : amont retrouvé à l'octet. Seule la CI Linux dira si la cause est bien celle-là.

## Suite : CI Linux, seconde cause (ddc487ce : `#context recouvre #tour`, R20 à 768 px)

Décision entre (a) et (b) : **(a)**. Preuves : le graphe Équipe est écrit avec `tour: []` (`vf-cockpit-equipe-carte.mjs:49`) ; `70-CONTEXT.md` P70-D-02 vise Code et Projet (visite Projet propre, P70-D-13), aucune décision ne prévoit de visite sur Équipe ; le repli `autoSteps()` y raconterait « La base de code » à propos de sessions et de sous-agents. La visite s'y ouvrait pourtant : `75-vf-modele.js` (démarrage d'office, 700 ms après le rendu) et `maybeAuto()` de `40-tour.js` appellent `start()` sans condition d'onglet ; elle s'ouvre dès que le graphe a deux cartes (sous Linux, plus lent, les cartes de l'équipe sont déjà là à ces 700 ms ; en local le lab de la suite n'en a pas encore).

Condition reproduite plutôt que la plateforme : lab avec une session et un sous-agent (HOME jetable), onglet Équipe à 768 px, `start()` appelé sans argument comme le démarrage d'office.

### Rouge — 289d1ac6 (tête avant correction)

Sonde `chrome-visite-etapes.mjs … 768 equipe` : `{"e768":{"cartes":2,"auto":true,"manuel":true}}` — la visite s'ouvre sur Équipe par l'appel d'office (`auto` vrai, attendu faux). Témoin O6.14 de `test-cockpit-projet.sh` : attendu `[false]`, obtenu `[true]` (mesure faite à la sonde avant le patch, la suite n'a pas été rejouée sur l'ancien arbre).

### Correction et vert

`start(manual)` : le démarrage d'office (sans argument) ne fait rien sur l'onglet Équipe ; le bouton « Par où commencer » (`start(true)`) l'ouvre toujours (O6.14b). Cette décision n'invente aucune visite : elle retire un repli involontaire. Choix (b) non retenu (carte de visite écartée de `#context`) : sans visite sur Équipe, aucune carte à placer ; si une visite manuelle y est ouverte, le recouvrement de `#context` par une carte haute reste possible (non mesuré).

`test-cockpit-projet.sh` 106 PASS / 0 FAIL (O6.14a, O6.14, O6.14b) ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 70/0 ; `test-cockpit-responsive.sh` 255 PASS / 6 FAIL (les six R13.4) ; `synchro.sh verifier` : amont retrouvé à l'octet.

## Suite : CI Linux, R15.4b (03bada92)

`R15.4b — Projet / 390 px : Échap ferme le tiroir` : attendu `[false]`, obtenu `[true]` sous Linux, deux fois sur le shard 6.

**Hypothèses instruites (macOS, condition forcée).** (1) Une visite ouverte capte la première Échap (écouteur de capture de `40-tour.js`), le tiroir reste ouvert : vérifié. (2) L'ouverture ou la sortie de la visite touche l'état du tiroir : faux. Mesure à 390 px sur Projet, une carte ouverte dans le tiroir : visite démarrée → tiroir ouvert, visite active ; Échap 1 → visite fermée, tiroir ouvert ; Échap 2 → tiroir fermé. Les trois états sont repris par O6.15 (la visite, couche du dessus, capte la première Échap, c'est le bon ordre pour une personne ; le tiroir n'est jamais touché par la visite).

Le lien avec 5e503058 est un effet de calendrier, pas de code : ce commit ne change pas l'ouverture d'office sur Projet. Sous Linux, plus lent, la visite d'office (700 ms) s'ouvre pendant la mesure ; sous macOS, l'Échap de R15.4b part avant. Non vérifié sous Linux.

### Rouge — condition forcée sous macOS, tête 03bada92

`chrome-responsive.mjs` avec l'injection d'`INJ_ECHAP` précédée de `window.VibeFlowTour.start()` : `tiroir = true` (attendu `false`) : R15.4b rougit.

### Correction et vert

Le défaut est dans la condition de mesure, pas dans la visite : `INJ_ECHAP` (section R15 de `test-cockpit-responsive.sh`, seule retouche de la suite) ferme la visite (`window.VibeFlowTour?.end()`) avant l'Échap ; la visite n'est pas marquée « vue ». Assertion R15.4b inchangée. `test-cockpit-responsive.sh` 255 PASS / 6 FAIL (les six R13.4 ; R15.4b vert) ; `test-cockpit-projet.sh` 108 PASS / 0 FAIL (O6.15a, O6.15) ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 70/0.

## Suite : tri de goût de Samuel (P70-D-23 ; « Tout selon les recos (Recommandé) », AskUserQuestion, session principale Claude Code, 2026-11-04)

Q4a et Q5a (centrage borné, visite qui éclaire sans sélectionner) : ratifiés, rien à changer. Points repris ici : Q6b, Q7b, Q9b, Q13a.

### Rouge — tête b0182676 + témoins

- Q13a, O6.14b inversé (le bouton n'ouvre plus de visite sur Équipe, il est `aria-disabled`, son infobulle nomme l'onglet) : `test-cockpit-projet.sh` 108 PASS / 1 FAIL, attendu `[false|true|true]`, obtenu `[true|null|false]`.
- Q6b, O6.16 (lab Projet à quatorze phases, 390 px, largeur à l'écran de chaque carte ciblée ≥ 120 px) : sonde `chrome-visite-etapes.mjs` sur ce lab, largeurs des étapes `[159, 108, 303]` px (plafond de zoom ×1,6, bornage par le graphe entier) : l'étape 2 fait 108 px. L'assertion O6.16 n'a pas été rejouée dans la suite sur l'ancien arbre : mesure à la sonde.

### Vert

`test-cockpit-projet.sh` 109 PASS / 0 FAIL (O6.14b inversé et O6.16 verts, O5 et O6.10 verts) ; `test-cockpit-onglet-code.sh` 25/0 ; `test-cockpit-chrome-fr.sh` 73/0 (trois chaînes ajoutées au corpus F11) ; `test-cockpit-vendor.sh` 79/0 ; `synchro.sh verifier` : amont retrouvé à l'octet. Suite responsive non rejouée (consigne).

- Q6b : sous 701 px le plafond de zoom passe de ×1,6 à ×4, l'objectif d'une carte est 60 % de la zone libre, et le bornage par le graphe entier ne s'applique plus (il ne tient pas à cette taille) ; au-dessus de 701 px il reste (O6.10 vert). Largeurs à 390 px sur le lab à quatorze phases : `[215, 215, 303]` (avant `[159, 108, 303]`), toutes ≥ 120 px. **Risque à rejouer** : à 390 px la visite d'office zoomée laisse le reste du graphe hors de l'écran ; les mesures de la suite responsive qui comptent « une carte sort de la zone libre » à 390 px avec la visite ouverte pourraient rougir.
- Q7b : l'étape « services extérieurs » (plusieurs services) allume les cartes des services (jusqu'à six, `hl` sur chaque carte, `dim` sur le reste), en plus du contour du titre de la vue d'ensemble. Construite par `autoSteps()` de `40-tour.js` ; aucun nouveau test (réglage de contenu), O5 rejoué vert. Non vérifié visuellement : les labs de la suite n'ont pas de services extérieurs.
- Q9b : dernier pas : « depuis le bouton de visite (icône) en haut » quand le bouton n'affiche que son icône (sous 1 600 px), « ⋯ › Par où commencer » sous 700 px, « Par où commencer » en haut sinon ; infobulle « de ce projet » sur l'onglet Projet, « de ce code » ailleurs.
- Q13a : sur l'onglet Équipe, `start()` ne fait rien et le bouton est `aria-disabled`, atténué, avec l'infobulle « Pas de visite pour l'onglet Équipe ».

## Suite : classe visite / surfaces (CI Linux de 07e75a54 : R3 « #zoom recouvre #tour » à 800 px)

Quatrième instance de la même famille (`#panel` puis `#context` en R20, Échap en R15.4b, maintenant `#zoom`) : la carte de visite ne regarde que le panneau, la barre de question et sa cible, pas les autres surfaces fixes. On ferme la classe.

### Rouge — 07e75a54, témoin génératif O6.17 (sonde `chrome-visite-etapes.mjs`, champ `surfaces`)

Visite ouverte par l'API (aucune course de calendrier), Code et Projet, 390 / 768 / 800 / 1 024 / 1 440 px, surfaces visibles : `#zoom`, `#panel`, `#context`, en-tête, `#ask` et ses avis, contour de la cible. Mesure de la sonde sur le code d'avant correction :
- Code, 800 px : étape 1 `#zoom` ; étape 2 `#zoom+#context`.
- Projet, 800 px : étape 2 `#context` ; étape 4 `#zoom+#context`.
- Toutes les autres largeurs : aucune surface recouverte (390, 768, 1 024, 1 440).
Les assertions O6.17 de la suite n'ont pas été rejouées sur l'ancien arbre : mesure à la sonde.

### Correction et vert

- `place()` de `40-tour.js` (patch P25) : la carte de visite est placée par recherche déterministe. Obstacles visibles : `#zoom`, `#panel`, `#context`, en-tête, `#ask` et ses avis, contour de la cible. Candidats : largeur (360, 300, 260, 220, 200), côté (gauche, droite), hauteur au-dessus de chaque obstacle ; hauteur maximale bornée par la place sous l'en-tête et le titre (le texte défile). Coût : surface recouverte (poids dominant), puis distance à la place habituelle ; égalités départagées par l'ordre fixe. Replacée dès qu'une surface bouge (relevé toutes les 200 ms tant que la visite est ouverte). Aucun paramètre de calendrier, de police ni de pointeur.
- Mesure à la sonde après correction (visite ouverte par l'API, Code et Projet, 390 / 768 / 800 / 1 024 / 1 440 px) : aucune surface recouverte à aucune étape, centrage et carte dans la zone libre conservés. Deux essais intermédiaires ont montré des défauts que le témoin a vus : une hauteur non bornée (800 px, `#context`), des surfaces qui bougent après le placement (390 px, `#zoom` : zone replacée au fil de l'eau), et un coût « premier candidat sans recouvrement » qui rejetait la carte trop haut (centrage perdu à 390 px) ; le coût par distance l'a corrigé.
- Suite responsive déterministe face à la visite d'office : `chrome-responsive.mjs` attend, avant chaque mesure, que la visite d'office soit ouverte ou qu'elle ait eu tout son temps (1,8 s ; onglet Équipe et lien vers un endroit précis exemptés), puis mesure. Visite jamais marquée « vue ». `test-cockpit-responsive.sh` non modifié : aucune assertion touchée.
- Vert : `test-cockpit-projet.sh` 120 PASS / 0 FAIL (O6.17 à cinq largeurs, Code et Projet) ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 73/0 ; `test-cockpit-onglet-code.sh` 25/0 ; `test-cockpit-responsive.sh` deux fois de suite 261 PASS / 0 FAIL ; `synchro.sh verifier` : amont retrouvé à l'octet. Non vérifié sous Linux.

## Suite : toute largeur de police (CI Linux de 63efb1e1)

Constat CI : O6.17 [800 px] Projet `[2:#context 3:#context 4:#context]` ; R22 « #ask recouvre #tour » à 1 640 px ; R3 project / 390 px « carte : sort de la zone libre (88..532 / libre 0..390) ». Hypothèse : le runner Linux tombe sur DejaVu Sans, plus large que les polices de macOS ; les cartes et les textes y sont plus grands.

### Rouge — police large imposée sous macOS (63efb1e1 sans correction)

Mode « police large » (témoin générique, à garder) : la carte de visite, le titre et les cartes du graphe prennent Verdana puis DejaVu Sans avec un espacement de lettres de 0,06 em (sonde `chrome-visite-etapes.mjs` option `police`, suite responsive `RESP_POLICE=1` dans `chrome-responsive.mjs`). L'en-tête et la barre de question gardent la police du poste : sur toute la page, Verdana rend rouges R1 « invite tronquée » et R22 « #crumbs rogné » sans rapport avec la visite (DejaVu est moins large que Verdana, R1 passe en CI).
- `test-cockpit-projet.sh` copié hors dépôt depuis le commit de départ (`git archive`), passe « police large » O6.17p : 130 PASS / 1 FAIL — `O6.17p [800 px] — Projet, police large` attendu `[]`, obtenu `[2:#context 3:#context 4:#context]` : **identique à la CI**.
- Cause : la hauteur maximale de la carte ne comptait que les surfaces du haut situées avant la moitié de la fenêtre ; un titre allongé par la police dépassait ce seuil, la carte passait dessous.
- **Non reproduits sous macOS** malgré la police large : R22 (« #ask recouvre #tour » à 1 640 px) et R3 à 390 px. La suite responsive en police large donnait 284 PASS / 0 FAIL, sur le code de départ comme sur le code corrigé (la copie hors dépôt, `RESP_POLICE=1`). Ces deux rouges ne sont donc pas prouvés fermés ; les protections ajoutées ci-dessous sont celles que la géométrie justifie (voir « Correction »).

### Correction et vert

- (a) Zoom : le plafond se calcule sur la taille réelle de la carte ciblée (jamais plus de 92 % de sa zone libre, quitte à dézoomer), puis la carte est mesurée une seconde fois une fois le mouvement fini (700 ms) et visée de nouveau si elle dépasse encore sa zone. Sous 701 px, le bornage par le graphe entier revient tant que la carte reste lisible (≥ 120 px de large) : le zoom ne dépasse la taille du graphe que pour atteindre cette lisibilité (largeurs à 390 px sur le lab à quatorze phases : 159, 120, 303 ; avant : 215, 215, 303).
- (b) Placement : la hauteur maximale compte toujours le bas réel du titre et de l'en-tête (cause du rouge à 800 px, mesurée) ; si aucun emplacement n'évite toutes les surfaces à pleine hauteur, la carte se raccourcit à 240, 180, puis 120 px (le texte défile), après avoir essayé les largeurs jusqu'à 200 px.
- (c) `#ask` et ses avis étaient déjà des obstacles du placement et sont replacés quand ils bougent (relevé toutes les 200 ms). Je n'ai pas reproduit R22 (« #ask recouvre #tour » à 1 640 px) : aucune cause prouvée ; une marge de 6 px autour des surfaces a été essayée et retirée (elle choisissait des cartes inutilement étroites et faisait sortir le graphe de la zone libre à 1 024 px, R1 et O6.10 rouges).
- Vert, en série : `test-cockpit-projet.sh` 131 PASS / 0 FAIL (O6.17p, police large, aux cinq largeurs, Code et Projet) ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 73/0 ; `test-cockpit-onglet-code.sh` 25/0 ; `test-cockpit-responsive.sh` 284 PASS / 0 FAIL, deux fois sans police large et deux fois avec (`RESP_POLICE=1`) ; `synchro.sh verifier` : amont retrouvé à l'octet. `test-cockpit-responsive.sh` non modifié (aucune assertion touchée).
- À confirmer par la CI Linux : R22 et R3 à 390 px, non reproduits ici.

## Suite : géométrie réelle du runner (CI Linux de 6c75f230 : O6.17 et O6.17p rouges à 800 px, R22 à 1 640 px)

- **Police réelle.** DejaVu Sans 2.37 (TTF libres, téléchargées hors dépôt, dans le dossier de travail de la session) chargée par `@font-face` en `data:` et imposée à toute la page (`document.fonts.check` vrai, polices rendues relevées par CDP `CSS.getPlatformFontsForNode` : DejaVu Sans). `test-cockpit-projet.sh` avec `VF_DEJAVU_DIR` : 142 PASS / 0 FAIL, **O6.17d vert** aux cinq largeurs, Code et Projet : la police réelle ne reproduit pas le rouge de la CI sous macOS. La géométrie du runner diffère d'autre chose (rendu du texte sous Linux, hauteur du bloc titre, nom du lab).
- **Diagnostic imprimé à l'échec** (aucune assertion ne change) : pour chaque étape fautive de O6.17, O6.17p, O6.17d, O6.17t, une ligne `DIAG` : fenêtre, bbox de `#tour` (largeur, bas et hauteur max posés), de `#context` et de chacun de ses enfants visibles, de la cible, police calculée du titre, polices réellement rendues, polices chargées. Pour R22 : bbox de `#tour`, de `#ask` et de chacun de ses avis (caché ou non), de la fenêtre, et la liste des obstacles que `place()` a vus au dernier placement avec son choix (`window.VibeFlowTour.diag()`).
- **Piste testée.** Un bloc titre plus haut que prévu (description de 600 caractères) : rouge à 800 px, sonde `titrehaut`, sur le code de 4fc8039e — Code étape 1 `#panel`, étape 2 `#context` ; Projet étape 1 `#context`. Témoin O6.17t. La cause du rouge CI n'est pas prouvée être celle-là.

### Correction et vert (titre plus haut que prévu)

- Dernier recours : si, après toute la recherche d'emplacement, la carte de visite recouvre encore quelque chose, la description du bloc titre (`#context p`, le titre reste) est repliée pendant la visite et la recherche est refaite ; le repli n'est gardé que s'il recouvre moins, sinon la description est remise. Elle est remise à chaque nouveau placement et à la fin de la visite. Voie la moins invasive : aucune autre surface bougée, aucun fichier d'en-tête touché, effet limité à la durée de la visite.
- Passe « titre haut » (O6.17t) : cinq largeurs, Code et Projet, aucune surface recouverte (avant : Code étape 1 `#panel` et étape 2 `#context`, Projet étape 1 `#context`, à 800 px).
- Vert, en série : `test-cockpit-projet.sh` 153 PASS / 0 FAIL avec `VF_DEJAVU_DIR` (O6.17d, O6.17t) et 131 PASS / 0 FAIL + 1 passe sautée et dite sautée sans la variable ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 73/0 (le texte de diagnostic de `40-tour.js` est un JSON, pas une chaîne de l'interface : la première version rougissait F2) ; `test-cockpit-onglet-code.sh` 25/0 ; `test-cockpit-responsive.sh` 284 PASS / 0 FAIL ; `synchro.sh verifier` : amont retrouvé à l'octet.
- **R22 (« #ask recouvre #tour » à 1 640 px) : non reproduit, cause inconnue.** À 1 640 px la carte est au-dessus de `#ask` avec 12 px de marge, `#ask` est un obstacle et son relevé est repris toutes les 200 ms. Le diagnostic (bbox de `#tour`, de `#ask` et de ses avis, de la fenêtre, obstacles du dernier placement) s'imprime désormais à l'échec de R22 ; la prochaine CI Linux donnera la géométrie. Non prouvé fermé.

## Suite : R22 lu dans le diagnostic de la CI Linux (f41cfd25)

Mesure de la CI : `#tour` 16..276 (largeur posée 260 px), `#ask` à partir de x = 274, hauteur de 898 à 1 005 ; `choice: { width: 260, side: left, bottom: 76, covered: 0 }`. Le placement a jugé le recouvrement nul sur la bbox de la carte **pendant son animation d'entrée** (`tourIn` : 98 % de la taille, 8 px de décalage) : à 98 %, 260 px font 254,8 px, soit un bord droit à 273,4 < 274. Une fois l'animation finie, la carte fait 260 px et recouvre `#ask` de 2 px. Rien à voir avec une police : tout poste le fait quand une surface tombe à moins de 2 % de la largeur du bord de la carte, et la surface ne bouge plus ensuite (le relevé de 200 ms ne la voit pas bouger).

### Rouge — 3312418f, passe « tangente » (sonde `chrome-visite-etapes.mjs`, option `tangent`)

`#ask` (avec un avis : plus haute) immobile, à x = 374 (2 px dans le bord de la carte de 360 px), visite ouverte par l'API : à 1 024 et 1 440 px, Code et Projet, étape 1 : `#ask` et `#ask>ask-form` recouverts. Les assertions O6.18 n'ont pas été rejouées dans la suite sur l'ancien arbre : mesure à la sonde.

### Correction et vert

- Cause du placement jugé libre à tort : `place()` jugeait la carte sur `getBoundingClientRect()`, la boîte peinte, réduite à 98 % et décalée de 8 px pendant l'animation d'entrée. Elle juge maintenant la boîte de mise en page (`offsetLeft`, `offsetWidth`, `offsetTop`, `offsetHeight`), la même que la carte posée, et compte 2 px de marge autour de chaque surface (bordures et arrondis que la boîte de mise en page ne montre pas). 6 px faisaient rougir R1 et O6.10 : 2 px est la plus petite marge de l'intervalle demandé ; la boîte de mise en page est la vraie correction (sans la marge, le témoin O6.18 est déjà vert).
- Vert, en série : `test-cockpit-projet.sh` 165 PASS / 0 FAIL avec `VF_DEJAVU_DIR` (O6.18 et toutes les passes) ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 78/0 ; `test-cockpit-onglet-code.sh` 25/0 ; `test-cockpit-responsive.sh` 291 PASS / 0 FAIL, sans et avec `RESP_POLICE=1` ; `synchro.sh verifier` : amont retrouvé à l'octet.
- (a) Mesurer la bbox rendue après la pose : non ajouté, devenu inutile : la boîte de mise en page est celle de la carte posée ; le relevé de 200 ms replace déjà dès qu'une surface bouge. O6.17 à 800 px : diagnostic CI pas encore reçu.

## Suite : R1 « long / project / 1 024 px » intermittent (CI Linux de 83b13be4, code identique à a15b073d vert)

`R1 — long / project / 1024 px` : `carte : sort de la zone libre (245..692 / libre 0..648)`.

### Mesure : synchronisation ou produit ?

Lab « long », onglet Projet, 1 024 px, panneau ouvert, graphe relevé toutes les 15 à 100 ms après l'ouverture de la visite d'office, avec et sans ralentissement du processeur (CDP `Emulation.setCPUThrottlingRate` ×4, ×6, ×10, ×12) :
- la transformation du graphe se stabilise entre 0,7 s et 1,2 s après l'ouverture ; à aucun instant du transit, ni à l'état stable, une carte ne sort de la zone libre (états stables relevés : 163..616, 115..616, 65..567 sur 648 selon la course de l'ouverture : `k` 0,616 ou 0,681) ;
- `mesurer()` de `chrome-responsive.mjs` prenait déjà un relevé quand deux relevés espacés de 250 ms sont identiques : la course « mesure en plein transit » n'est possible que si l'animation se fige au moins 250 ms, ce qu'un runner lent peut faire. Elle ne se déclenche pas sur ce poste : **non reproduite, ni en transit ni à l'état stable avec la géométrie ordinaire**.
- Le rouge CI (245..692) est à droite de tous les états stables relevés ici (163..616 au plus) : un graphe 82 px plus loin à droite. Cela ressemble à un état stable atteint par un autre chemin.

### Rouge — état stable, produit (carte de visite haute)

Hypothèse retenue et reproduite : la carte de visite est plus haute (texte long, police large) ; la zone « à côté » devient la plus grande et étroite ; `aim()` y centre la carte ciblée et pousse le reste du graphe sous le panneau. Sonde `chrome-visite-etapes.mjs` option `cartehaute` (carte de visite de 300 px de haut au moins), lab « nom long », Projet, 1 024 px, étape 1 : tout le graphe hors de la zone libre (`toutLibre` faux ; `{"chip":[139,226,370,365],"zone":[384,202,616,678],"free":[16,202,616,678],"all":[139,226,616,673],"chosen":[246,145]}` : centré dans la zone, graphe poussé à 862). Rouge à 300, 340, 380 et 420 px de hauteur, vert à 260.

### Correction et vert

- `aim()` : si le graphe entier tient dans la zone libre mais que centrer la carte ciblée dans sa zone l'en fait sortir, il cherche, parmi les déplacements qui gardent tout le graphe dans la zone libre, celui qui est le plus proche du centrage et qui laisse la carte ciblée visible et hors de la carte de visite. Sans déplacement possible (carte de visite de 440 px de haut forcée : aucun emplacement n'existe), il centre comme avant.
- Synchronisation (`chrome-responsive.mjs`) : avant chaque mesure, après l'ouverture de la visite et après l'injection éventuelle, attente que le graphe (cadre englobant des cartes), la carte de visite et la transformation soient identiques sur des relevés espacés de 150 ms pendant au moins 800 ms, sans classe « anim » (plafond 6 s). `RESP_SANS_ATTENTE=1` retire cette attente (mutant) ; `RESP_COURSE=1` impose un transit avec un arrêt de 700 ms.
- **Témoin de course : non démontré.** `mesurer()` met plus de temps que mon transit forcé (2,5 s) : avec ou sans l'attente, la mesure tombe après la fin du transit, rouge impossible à obtenir de façon déterministe avec ce harnais sans réécrire `mesurer()`. Les deux variables restent dans la suite comme outils de diagnostic ; je ne présente pas la synchronisation comme prouvée.
- Taille : `40-tour.js` a dû repasser sous 300 lignes (`check-file-size.sh`, V4 de `test-cockpit-vendor.sh`) : 299 lignes, le relevé d'`aim()` exposé au diagnostic a été retiré pour cela.
- Vert, en série : `test-cockpit-projet.sh` 169 PASS / 0 FAIL avec `VF_DEJAVU_DIR` (O6.19 aux trois largeurs incluse) ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 78/0 ; `test-cockpit-onglet-code.sh` 25/0 ; `test-cockpit-responsive.sh` **trois fois de suite** 291 PASS / 0 FAIL ; `synchro.sh verifier` : amont retrouvé à l'octet. Le rouge CI intermittent lui-même n'a pas été reproduit : la cause tenue (carte de visite haute) est une hypothèse, la correction de l'état stable est testée, l'attente de calme est une protection.

## Suite : garantie de construction du cadrage (CI Linux de 6498ed80 : O6.19 rouge à 1 024 px)

Le correctif précédent (chercher un déplacement qui garde le graphe dans la zone libre, à zoom fixé) échouait encore quand aucun déplacement n'existe à ce zoom (carte de visite haute, zone étroite). Garantie de construction demandée par le manager.

- `aim()` au-dessus de 701 px : le zoom visé est réduit par paliers de 8 % (jusqu'à 40 % du zoom qui remplit juste la zone libre) jusqu'au premier zoom où une translation garde TOUT le graphe dans la zone libre (hors panneau, titre, en-tête, barre de question) avec la carte ciblée visible et hors de la carte de visite ; la plus proche du centrage dans la zone est retenue. Seule exception, documentée : si même ce plancher ne laisse pas la carte ciblée visible hors de la carte de visite, elle reste sous la carte de visite, au zoom qui remplit juste la zone libre, le graphe entier restant dans la zone libre. Plus de repli « centrer comme avant ». Sous 701 px, comportement inchangé (zoom lisible, le graphe peut sortir de l'écran).
- Contraintes poussées plus loin que la CI : carte de visite de 420 px de haut au moins (puis 600 px à la sonde), seule, avec police large (`police`), avec la vraie DejaVu Sans (`dejavu`), à 768, 1 024 et 1 440 px, Projet, lab « nom long » : O6.19 vert sur les trois passes ; à la sonde 420 et 600 px : tout le graphe dans la zone libre, carte ciblée ni recouverte ni hors de sa zone, aux trois largeurs. Aucun lab des suites n'atteint l'exception.
- Mutant (copie hors dépôt de `plugin/`, `const P = ...` remplacé par `{ k: f, dx: dx0, dy: dy0 }`, le repli « centrer comme avant ») : rouge à la sonde, carte de visite de 420 px, `toutLibre` faux à 1 024 et 1 440 px (étape 1) ; vert à 768 px, où le graphe tenait déjà.
- Diagnostic à l'échec de O6.19 (et de O6.17) : zone libre, bbox du graphe, zoom avant la visite et zoom retenu, carte ciblée, en plus des bbox existantes. Le zoom « visé » n'est pas exposé (`40-tour.js` est à 299 lignes, limite des 300) : le zoom avant la visite et le retenu en tiennent lieu.
- Vert, en série : `test-cockpit-projet.sh` 177 PASS / 0 FAIL avec `VF_DEJAVU_DIR` ; `test-cockpit-vendor.sh` 79/0 ; `test-cockpit-chrome-fr.sh` 78/0 ; `test-cockpit-onglet-code.sh` 25/0 ; `test-cockpit-responsive.sh` 291 PASS / 0 FAIL deux fois, et avec `RESP_POLICE=1` ; `synchro.sh verifier` : amont retrouvé à l'octet. `40-tour.js` : 299 lignes.
