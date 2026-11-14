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
