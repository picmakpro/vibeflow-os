# 71-FIX-A1 — correction ciblée (lot A1 : design et rendu), critique design 77/100 et F7 de l'audit

Base : `01fb340b`. Commits : `5373d7ea` (J3, J10, F7 partie xterm), `2a9bd835` (J1, J4, J5, J6, J7, J13). Aucun fichier du lot A2 touché.

## Constats, causes, corrections

| Constat | Cause mesurée | Correction | Témoin rouge sur `01fb340b` |
|---|---|---|---|
| J3 traits de boîte | le sous-ensemble latin ne couvre pas U+2500-259F : Chrome dessine les traits en Menlo (15 px de haut) dans des lignes de 17 px, d'où des coutures aux densités fractionnaires | JetBrains Mono 2.304 Regular, release officielle (sha256 `a9cb1cd8…`), face `unicode-range:U+2500-259F`, poids `100 900` | T15.1 : `d1=0 d1.25=26 d1.5=22 d2=0 d2.2=28` trous de pixels |
| J1 barre | `etats` disait « Arrêté » pour refuse et expire | table unique : « Déjà ouvert », « Session expirée » | T20.1 : `refuse=Arrêté/refuse/Arrêté expire=Arrêté/expire` ; T20.2 `false false` |
| J6 | la grille xterm vide et son curseur restent sous la carte | classe `vf-q-cache` (visibility) posée par la carte « déjà ouvert », retirée par tout changement d'état | T20.3 : `terminal=true xterm=true curseur=1` |
| J5 | rien n'empêche le renvoi à la ligne dans la commande | bloc `nowrap` (commande + point final) dans Q et dans P | T20.5 Q : `260:coupee, 280:coupee` ; P : sept largeurs sur huit coupées |
| J4 | le contour était sur la poignée pleine largeur | contour sur `.vf-term-grip` | T20.4 : `poignee=solid grip=none` |
| J7 | boutons de 28 px, jamais relevés | `@media (pointer: coarse)` : boutons 44 px, barre 52 px | T20.7 : `tactile=true false false` |
| J13 | `:focus-visible` global sur une carte `tabindex=-1` focalisée par script | `.vf-q-carte:focus-visible { outline: none }` | T20.6 : `contour=solid` |
| J10 | parité F7 limitée aux 25 variables | T19 : 15 couleurs de la palette ayant une variable d'origine, par thème | quatre mutants M-PALETTE rouges (la palette actuelle est déjà conforme : pas de rouge sur `01fb340b`, c'est le mutant qui prouve la sonde) |
| F7 xterm | aucune assertion ne gardait `allowNonHttpProtocols: false` | T16 : https s'ouvre, `javascript:` et `data:` non | M-PROTO : `ouvertures.length` 3 au lieu de 1 |

Traces complètes : `fixA1-old-*.out` du scratchpad de la session (suites nouvelles rejouées sur un `git archive` de `01fb340b` : tiroir 35 PASS / 8 FAIL, page 43 / 6, vendor 93 / 11, xterm 22 / 2 dont T15.1).

## Trois pièges mesurés en route (à garder)

1. **Un poids exact casse la cellule.** Une face déclarée `font-weight:400` (ou 700) change la police primaire du moteur DOM : la cellule passe de 17 à 15 px (mesuré par `.xterm-char-measure-element`, 5 chargements sur 5). Avec `100 900`, 17 px. D'où un seul fichier (Regular), sans variante grasse : le gras des traits n'est pas synthétisé. TF.3 garde la déclaration.
2. **La densité se règle par émulation avant la navigation, et la cellule doit être celle de JetBrains Mono.** xterm mesure la cellule à l'ouverture ; si la police n'est pas encore décodée il mesure Menlo (15 px) et rien ne remesure. T15 recharge jusqu'à 5 fois jusqu'à obtenir une cellule ≥ 16,5 px, sinon échec nommé (jamais de vert à vide).
3. **Mes premières mesures ne voyaient rien** (0 trou, même avec la police fautive) : la cellule y était de 15 px (voir 2), et à 15 px les traits de Menlo se recouvrent. Le piège est la cellule, pas la densité ni le GPU : l'émulation de densité du protocole reproduit la couture dès que la cellule fait 17 px.

## Résultats (arbre à `2a9bd835`)

xterm 24 PASS, tiroir 43, page 49, vendor 110 (bash et zsh), xss 17, activation 40, securite 88, chrome-fr 26, reseau 14, assemblage 40, marque-blanche 22 ; `synchro.sh verifier` 0 ; `check-machine-paths`, `check-file-size --all`, `check-python-isolation` verts.

## Findings pour le manager

- **Cellule mesurée avant le chargement des polices (client.mjs, lot A2 ou manager).** Sans police en cache, le premier affichage mesure 15 px et les rangées gardent 15 px ; avec la police en cache, 17 px. Avec la police fautive les traits restaient continus à 15 px (mesuré) ; la hauteur de ligne dépend en tout cas de l'ordre de chargement (non mesuré avec la police corrigée à 15 px). Remède probable : créer ou remesurer le terminal après `document.fonts.load`. Non touché (hors périmètre).
- **Pastille fermée (32 px) non relevée sous `pointer: coarse`** : le mandat ne vise que les boutons de la barre.
- **Poids de page** : +92 Ko de police, soit environ +123 Ko base64 par chargement de Q.
