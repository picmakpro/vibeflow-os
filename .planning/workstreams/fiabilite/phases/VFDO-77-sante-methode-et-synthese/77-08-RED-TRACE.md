AVANT a703f6f972d6137a94d28c123c57a13ec777e527
# 77-08 — témoins rouges du bloc « Depuis votre dernière visite »

Commit de départ : voir la première ligne. `plugin/cockpit/VERSION` : v1.4.0. Empreintes (`git hash-object`) à ce commit :
`ui/00-vibeflow.js` 2c8693b2cc80ad3912d95d912557b6db5abcbfda · `ui/20-health.js` 9898b5af0493e566e5df67a034cec485848ca5ed · `ui/74-vf-synthese.js` c599e899022f794ca4ff4bafca112d2567384595.

## Suite `test-cockpit-synthese-visite.sh` sur le code présent (aucun fichier `74-vf-synthese-visite.js` ni `-style.js`)

Durée : 139 s. Résultat : 11 PASS / 31 FAIL. Les sondes positives des outils du banc sont vertes (B1 à B5 : lab avant/après, couleur teintée vue, stockage relu,
interception vue par la page, `storage` reçu par le second onglet, différence vue par le calcul de 77-04).

Rouges (assertion, attendu, obtenu), les cinq que le plan nomme :
- V1 — attendu `premiere|0|Première visite sur ce poste Le cockpit garde le repère …|Première visite sur ce poste` ; obtenu `erreur:Cannot read properties of null (reading 'etat')` (le bloc n'existe pas dans le panneau).
- V2.1 — attendu `true,true,true,true,true,true,true,true,Tout vu` ; obtenu `erreur:Cannot read properties of null (reading 'texte')`.
- W15 — attendu `undefined,0,0,0,true,0` ; obtenu `erreur:Cannot read properties of undefined (reading 'xss')` (aucun texte du lab rendu : rien à observer).
- W11 et W12 sont VERTS à la base, et l'écrire est honnête : W11.1 ne voit que la clé que le banc a posée lui-même avant le chargement (la page n'écrit rien), W12 est vert parce que
  77-03 a déjà retiré la prose. Leur rôle est de rester verts une fois le bloc livré ; V7 (la page écrit `courante` à la navigation) porte le rouge de l'écriture : attendu `1,true,v+precedente+courante`, obtenu `1,false,…` (âge de la courante : celle du banc, pas récente).

Hors plan à la base : aucun rouge de ces suites n'est du fait de ce plan.
