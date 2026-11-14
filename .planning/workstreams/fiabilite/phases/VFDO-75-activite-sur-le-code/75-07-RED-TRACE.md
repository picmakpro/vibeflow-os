# 75-07 — RED-TRACE (première moitié : le canal de marquage)

Régime allégé : mutants levés (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Cette trace ne porte donc que
l'étape 0 et le rouge de base.

## Étape 0 — en-tête

- Base du rouge : `7de88974` (`git rev-parse --short HEAD` au moment de la mesure ; porte 79-16, ne porte ni 79-17 ni 79-18).
- Forme livrée de `VENDORED.txt` : en-tête de quatre lignes (origine, fork assumé P79-D-07, forme des lignes machine, sentinelle), puis une ligne `AJOUT <chemin>`
  par fichier à nous, rangée par chemin croissant octet par octet (contrôle V10.5) ; la ligne du canal s'insère entre `assets/ui/73-vf-tiroir-travail.js` et
  `assets/ui/75-vf-modele.js`. Aucune ligne de patch.
- Plafond de `viewer.html` : non mesuré, ce fichier n'est pas touché par cette moitié.

## D1 rouge sur la base

Commande : `MARQUES_JS=<module absent> bash plugin/cockpit/scripts/tests/test-cockpit-activite-carte.sh` (le module `ui/75-vf-marques.js` n'existe pas sur la base).

```
== D1 le canal existe, l'objet du moteur n'est pas étendu ==
  ❌ FAIL — D1 : window.VF_MARQUES expose poser, retirer, active et lire
     attendu: [poser:function retirer:function active:function lire:function]
     obtenu:  [ABSENT]
BILAN : 0 PASS, 1 FAIL
```

Le harnais rend `D1.api=ABSENT` quand le fichier du canal est illisible : l'échec est bien « module absent » (le harnais, lui, s'exécute : code 0), pas une erreur du harnais
(un harnais en échec rend `D0`, ligne distincte). Mêmes raisons pour D2 à D20, qui n'ont pas de rouge propre : la suite s'arrête au premier FAIL, et le harnais ne
produit aucune observation de D2 à D20 sans module.

## Vert

Après `ui/75-vf-marques.js` : `BILAN : 35 PASS, 0 FAIL` (D1, D2, D2b, D5 avec D5b, D18, D19, D20).

## Témoin D1 : ce qu'il mesure

`Object.isFrozen(window.VibeFlow)` et l'égalité des clés avant et après la pose, le retrait et la repose d'une couche, et deux compteurs sur les méthodes `render` et
`rerender` du moteur factice (0 + 0 : aucune relance du placement par le canal). Le canal ne lit `window.VibeFlow` (repli `window.Floorplan`) que pour `chain` et `on`.

# 75-07 — seconde moitié : la marque sur la carte (tâches 1 à 3)

Régime allégé : mutants levés, SAUF la chaîne XSS de la marque (D3, D15 : témoin rouge puis vert ET mutant vu rouge). Base du rouge : `3a80d45e` (`git rev-parse --short HEAD` au
moment de la mesure ; tête de la Phase 75 après 79-16, 79-17, 79-18, 79-22). Plafond de `viewer.html` : `.html` est hors de la baseline des colonnes (`TAILLE assets/viewer.html .html,
hors gate` dans `VENDORED.txt`), aucun plafond à mesurer ; `colonnes-cliquet.mjs verifier` : OK avant et après chaque tâche.

## Tâche 1 — D3 et D4 (marque en place, géométrie invariante)

Rouge sur la base (la marque n'est pas encore dessinée : le canal pose, aucun peintre ne la met dans le pied) :

```
== D3 la marque, le mot par textContent, noms hostiles ==
  ✅ PASS — D3 : le dossier aux fichiers hostiles (balises, très long, U+2028) garde ses 17 cartes
  ❌ FAIL — D3 : une marque posée sur une carte ajoute UN .lm dans son pied
     attendu: [1]
     obtenu:  [0]
BILAN : 37 PASS, 1 FAIL
```

Vert après le peintre de `ui/75-vf-marques.js` (`peindre`, branché par défaut ; point d'entrée public `brancherDessin` inchangé). Mutants vus rouges (chaîne XSS) :

- `MUTANT-ROUGE — D3-texte-par-innerHTML` : `e.textContent = txt` devient `e.innerHTML = txt` dans la copie du module ; le mot hostile (`<img src=x onerror=window.__xss=1>…`) injecte un
  élément `img` dans le pied (D3 : `injectes > avant`, `xss` faux). Le témoin sur le module réel rend `injectes = avant`, `xss` vrai.
- `MUTANT-ROUGE — D4-pose-relance-le-placement` (non exigé par le régime allégé, joué parce qu'il prouve que la mesure n'est pas aveugle) : `change()` appelle `rerender()` ; le compteur
  sur `on('render')` passe au-dessus de 0 (D4 rouge).

D4 : 18 séries (1440, 1024 et 390 px ; deux conteneurs ; trois paliers de zoom), chacune avec poser, retirer, cinq bascules et une mise à jour de la couche ; la mise en page en worker
est attendue stable (`stabiliser`, deux relevés identiques) avant chaque relevé. Les cartes de fichier d'un dossier n'ont pas encore de pied à ce stade (neuf séries sans marque, comptées
comme telles) : la réserve du pied (tâche 2) porte la mesure aux 18 séries.

## Tâche 2 — D6 à D12, D17 (pied réservé, glyphes, contraste, zooms)

Rouge sur la tête de la tâche 1 (`8d3459ba`) : D4 attend 18 séries marquées et en obtient 9 (les cartes de fichier d'un dossier n'ont pas de pied, la marque n'a nulle part où se poser) ;
D6 : 31 cartes de fichier dont 30 sans pied (obtenu : hauteurs `[null, 20]` sur `src/a`, `[null]` sur `src/b`, aux trois zooms ; attendu 20, 20, 28, 28).

Constats de la mesure (le témoin D9b a rougi d'abord, puis a été corrigé et re-mesuré, jamais affaibli) :
- D9b rouge avec la géométrie de la spec (barres de 3, écart de 1,5 unité : 0,945 px à k = 0,42, aucune colonne éteinte garantie) : `bas,moyen,haut` en défaut. Correction demandée par la spec
  (« élargir dans le viewBox et remesurer ») : barres en x = 1,5 / 6,5 / 11,5, largeur 3, écart 2 ; aires et hauteurs inchangées. Le critère « autant de hauteurs distinctes que de barres » se lit
  sur la colonne la plus haute de chaque barre (les colonnes de bord, à demi couvertes, varient d'un pixel selon le décalage).
- D9d : le confluent de la spec (tige jusqu'à y = 14, capuchon rond) sortait de [1,5 ; 14,5] ; tige ramenée à y = 13,5. Le bouclier évidé est le tracé du bouclier décalé de 1 vers l'intérieur
  (trait de 2 : le sommet reste à y = 1,5).
- Pavé d'encre, contraste et silhouettes : verts dès la première mesure (le contraste est calculé sur les couleurs résolues dans la page, deux thèmes ; `--recent` n'est employé que par « en cours »,
  `--recent-text` sur `.card.module`).

D8 (chiffres consignés, avant → après la réserve, lab de la suite : un nœud de 33 fichiers en deux dossiers virtuels) :

```
1440 px root : 2 cartes, 0 sans pied, hauteur 472 → 472, largeur 380 → 380, k 1.1 → 1.1
1440 px n:d-src : 2 cartes, 0 sans pied, hauteur 218 → 218, largeur 754 → 754, k 1.1 → 1.1
1440 px d:d-src|src/a : 16 cartes, 14 sans pied, hauteur 2206 → 2598, largeur 644 → 644, k 0.846 → 0.846
1440 px d:d-src|src/b : 17 cartes, 16 sans pied, hauteur 2340 → 2788, largeur 644 → 644, k 0.846 → 0.846
390 px : mêmes valeurs (k 0.852 / 0.846 / 0.846 / 0.846)
```

D8b : aucun k d'ouverture ne change de palier (0,65 et 0,42) à 1440 ni à 390 px : `ARRET-D25` non déclenché. Projet et Équipe : géométrie IDENTIQUE à 0 px à celle du module copié avec la réserve
neutralisée (D6b ; copie par `cockpit_module_muter_page`, ancre `const reserve = `) ; témoin positif : sur Code le module sans réserve compte des cartes sans pied, le réel n'en compte aucune.
D17 : le keyframe `vfrespire` n'est PAS chargé sur l'onglet Code (`71-vf-equipe-rendu.js` ne se pose que sur Équipe) : `75-vf-marques-glyphes.js` pose son propre keyframe `vfm-respire`
(mêmes valeurs : 1 → .82, 2,4 s) et sa coupure sous `prefers-reduced-motion` ; animation calculée `vfm-respire` en mouvement normal, `none` en mouvement réduit.
Voisines rejouées sans les affaiblir : `test-cockpit-moteur-carte.sh` (vert), `test-cockpit-equipe.sh` (vert, EK10 et le mutant d'équipe compris), `test-cockpit-responsive.sh` (R1 et R3 verts ; reste de la suite : voir le SUMMARY).
Mutants de D6b, D7, D8b, D9, D10, D11b, D12, D17 : levés (régime allégé).
