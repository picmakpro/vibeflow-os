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
