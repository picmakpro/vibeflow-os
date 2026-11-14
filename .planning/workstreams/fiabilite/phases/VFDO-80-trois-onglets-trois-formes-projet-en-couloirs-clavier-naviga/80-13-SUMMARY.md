# 80-13 — SUMMARY

## Livré
- `viewer.html` : le fragment porte `v`, `s`, `z` (k,x,y arrondis à 1e-3) et `git=1`. `setHash` garde les clés d'une liste fermée (`git`) et le `z` d'une
  sélection sur le même niveau (un changement de niveau le retire : le cadrage du nouveau niveau est le sien) ; `z` s'écrit en fin de geste de l'humain
  (zoom, pan relâché, pincement, `cadrer()` = bouton, touche F, palette), par `replaceState`, 250 ms après le dernier geste ; `readHash` borne `z`
  (`k` dans [0,08 ; 2,5], x et y finis, |.| ≤ 1e5, décimales seules) et l'ignore à côté d'un `v` inconnu ; appliqué par `transformer` au premier rendu (avant `ready`)
  et sur `popstate` (`after`). `paramVue(cle, valeur)` / `lireParamVue(cle)` : seul `git`, seule la valeur `1`, ne remplacent que leur jeton (`#t`, `#vf-x`, `#r=` intacts).
- `77-vf-git-tiroir.js` (249 → 264 lignes) : `git=1` écrit à l'ouverture, retiré à la fermeture de l'humain (pas au démontage d'un onglet), mémoire `sessionStorage`
  `vf-tiroirs:<nom du lab>` ; restauration (lien, puis mémoire) à la fin du rappel `surOnglet`, par `ouvrir(true)` : sans focus ; `vf:onglet` redit `git=1` après
  l'adresse posée par 80-10. `ouvrirSur` : aucune ligne touchée.
- `73-vf-tiroir-travail.js` (43 → 61 lignes) : mémoire (`travail`) écrite à chaque transition ouvert/fermé, rejouée une fois au premier passage où `#vf-lock` existe, sans focus.
- Suite `test-cockpit-lien-vue.sh` (14 PASS) et pilote `chrome-lien-vue.mjs`. Trace rouge : `80-13-RED-TRACE.md` (7 PASS / 7 FAIL sur la base).
- `wc -l` : viewer.html hors plafond (gabarit), 77 = 264, 73 = 61, pilote 147, suite 92. Aucune ligne neuve > 160 colonnes ; `colonnes-baseline.txt` non touché (cliquet vérifié :
  `73-vf-tiroir-travail.js` reste à 12 lignes longues). Balises `<script` de `viewer.html` : 6 avant, 6 après. Aucun fichier `ui/` neuf, aucune ligne `AJOUT`.

## Écarts
- Écart : `x` et `y` s'écrivent à 1e-3 (et non à l'entier) : « transformation à 1e-3 près » est ainsi vrai de k, x et y.
- Écart : restauration des tiroirs dans le rappel `surOnglet` (fin de `brancher` pour Git, premier passage de `etat()` pour « Au travail »), pas à `on('ready')` : la coquille
  exécute les rappels APRÈS `ready` (`lot` en fin de `sequence`) ; une accroche à `ready` s'exécuterait avant la pose du nœud du tiroir.
- Écart : LV2.4 (Git gardé par `VF_ONGLETS.aller`) était déjà vert sur la base (80-10 rouvre le tiroir) ; LV1.3 et LV3.2 aussi ; LV3.1 vert à vide avant la lecture de `z`,
  d'où le témoin positif LV3.1b (`#z=1.5,10.5,20.25`) ajouté.
- Écart : `chrome-session.mjs` (commun) — `naviguer` oublie les clés `vf-tiroirs:*` avant de charger, sauf `{ garderTiroirs: true }` : sans cela un tiroir ouvert par un scénario
  se rouvre au chargement suivant (c'est la fonction voulue) et fait basculer le clic du scénario d'après ; mesuré : OG2.4, OG2.5, OG2.10 à OG2.12 de `test-cockpit-onglets.sh`
  (suite de p10) et, sous charge, des lignes de `test-cockpit-git-tiroir.sh`. Trailer `Gate-Touche` posé. Ancre du mutant M-AJUSTEMENT de `test-cockpit-git-tiroir.sh` suivie
  sur la ligne de la touche F (`cadrer();`), même mutation.
- Écart : au changement d'onglet par `VF_ONGLETS.aller`, le moteur d'arrivée lit l'adresse DÉPART (80-10 pose l'adresse d'arrivée après `chargerOnglet`) : un `z` de l'onglet
  quitté s'applique au premier rendu de l'arrivée quand son `v` existe aussi (ou est absent) ; 80-10 le remplace aussitôt par la vue mémorisée si elle existe. À corriger côté 80-10
  (poser l'adresse avant le chargement, ou la nettoyer) ; non fait ici, `00-vf-onglets.js` n'est pas à ce nœud.
- Cas non écrits : aucun (79-18 non nécessaire).
- Mutants M-ZHORS, M-EFFACE, M-FOCUS-TIROIR : levés. rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Suites jouées sur la tête commitée (2ca77f50)
- lien-vue 14/0 (77 s) ; moteur-carte 73/0 (127 s) ; onglets 27/0 (86 s) ; git-tiroir 193/1 : M-SELECTION (rouge identique sur la base 2736fe67, rejouée : `80-a51` a rendu le volet idempotent,
  le mutant n'ouvre plus deux détails) ; vendor 250/2 : V4 (`70-vf-live.js` à 300, attendu) et V4c.9a (`41-vf-projet-clavier.js` réel=1 baseline=0, fichier d'un nœud voisin, non commité).
- responsive 378/1 : D39m3 (mutant de `39-vf-tour-placement.js`, fichier non touché ; non rejoué, 24 min sous charge) ; couloirs 72/0 (255 s, rejouée seule : une première passe sous charge avait rougi CL3.3c et CL3.4, cas d'un nœud voisin en cours).

## CHANGELOG demandé par 80-18
- Le lien de la barre d'adresse rend la vue : conteneur, sélection, zoom (`z`) et tiroir Git (`git=1`) ; l'état des tiroirs (Git, « Au travail ») survit au changement d'onglet et au rechargement
  (mémoire de session au nom du lab), sans prendre le focus ; un lien forgé est borné.
