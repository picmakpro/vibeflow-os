# 77-08 — Bloc « Depuis votre dernière visite » et feuille neutre : SUMMARY

## Livré

- `ui/74-vf-synthese-visite.js` (250 lignes, aucune ligne au-delà de 160 points de code) : bloc `visite` du registre de 77-05 (entrée remplacée en place à chaque exécution du script par onglet).
  Mémoire par lab (`vibeflow-cockpit:derniere-visite:<lab>`, lab inconnu : rien d'écrit), rotation au chargement, `courante` écrite et fusionnée à `visibilitychange` (caché) et `pagehide`,
  `storage` (relecture et rendu sans focus ni annonce), « Tout vu » (focus sur le `h3`, annonce « Synthèse remise à zéro. »), phases (5 puis « et N autres »), commits (« Plus de 500 »,
  « Commits : non lus »), sessions (« Au moins N », réserve des 24 h), blocages nouveaux (3 puis « et N autres », texte coupé à 140 caractères, `title` complet) et levés, liens « Voir dans Git »
  et « Voir dans l'onglet Équipe ». Abonnements `VF_ETAT` (`etat`, `who`, `git`) et écouteurs posés par `installer`, retirés par son nettoyage. Tout texte du lab par nœuds de texte.
- `ui/74-vf-synthese-style.js` (28 lignes) : feuille `.vf-sy` neutre (teinte des `.vst` neutralisée, grille par jetons `--sp-*`, quatre tailles, aucun mouvement, rien sur `#panel`).
- Suite `test-cockpit-synthese-visite.sh` (44 assertions : S0 à S6, D1, B1 à B5, V1 à V10, OB1, W4 à W7 dans les deux thèmes, W11, W12, W13v, W15, E0, M-INNER) ; scénario
  `chrome-synthese-visite.mjs` ; banc de 77-05 augmenté de `deuxiemeOnglet`, `intercepter`, `stockageLu`, `stockageAvant`, `labDeuxEtats` (chacun avec sa sonde positive, section B).
- Deux lignes `AJOUT` de `VENDORED.txt`, une ligne de durée de CI, README et CHANGELOG du module (mémoire de visite, effacement, persistance, limites, `base.h` de `cockpit-git@1`),
  `77-08-RED-TRACE.md`. Compteur de suites des README racine : 245, déjà au compte du gate (`check-version-sync.sh` vert). Aucune VERSION bumpée.

## Écarts

- Écart : le traceur et le bloc complet sont dans un seul commit de code ; la ligne `AJOUT` de VENDORED entre avec chaque fichier (un `AJOUT` sans fichier rougirait le plafond au commit précédent).
- Écart : le scénario est un fichier neuf du banc (`chrome-synthese-visite.mjs`, mode `visite` de `chrome-synthese.mjs`) et non une addition à `chrome-synthese-scenarios.mjs` (taille) ; le banc de 77-05 n'est pas recréé.
- Écart : `labDeuxEtats` met la branche du lab fixture en `main` : la base du cockpit est la branche `main` (arbres.mjs), sans elle `base.h` est nul et les commits arrivés sont inconnus (ligne omise).
  Sur un lab dont la base n'est pas `main`, le bloc ne compte donc pas les commits : dit dans le README.
- Écart : la ligne-résumé n'existe que Synthèse fermée (elle est dans l'aperçu) : le banc la lit panneau fermé, le nom accessible du bouton se lit dans les deux états.
- Écart : le lien « Voir dans l'onglet Équipe » s'affiche aussi sous la seule réserve des 24 h (aucune session visible), pas seulement avec N > 0.
- Écart : `.vf-sy .btn` prend 12,5 px dans la feuille (le `.btn` du viewer est à 13 px, hors des quatre tailles du contrat) ; W5 ne juge pas les décalages `top/left/right/bottom` de la zone vive masquée `.sr`
  (de 77-05, `position: absolute` : ces valeurs sont sa place dans le flux, pas un espacement).
- Écart : une interception du banc ne répond qu'aux requêtes de son motif (les écoutes CDP sont permanentes : sans cela deux interceptions successives se disputent la même requête).
- Écart : le commit de documentation embarque les derniers ajustements de la suite et le `font-size` du `.btn` de la feuille (commit unique, trace dans `git log`).
- OB1 : jugé avec les vrais blocs de 77-06 (visite, burnup, methode), ses commits `(77-06)` étant dans la branche au moment de la mesure.

## Suites jouées (sur la tête commitée)

- `test-cockpit-synthese-visite.sh` : 44 PASS / 0 FAIL (48 s, tête commitée, `performance.timeOrigin` prouvé en V10) ; `css-jetons.mjs` sur les deux fichiers : 0 ; cliquet de colonnes : conforme.
- `test-cockpit-synthese-page.sh` : 38 PASS / 0 FAIL (24 s) ; `test-cockpit-synthese-blocs.sh` : 59 PASS / 0 FAIL (28 s) ; `test-cockpit-chrome-fr.sh` : 141 PASS / 0 FAIL (37 s) ;
  `test-cockpit-vendor.sh` : 252 PASS / 0 FAIL (95 s) ; `scripts/check-version-sync.sh` : vert (245 suites) ;
  `test-cockpit-transcript.sh` : 111 PASS / 0 FAIL (61 s) ; `test-cockpit-projet-visite.sh` : 114 PASS / 1 FAIL (684 s) — R3.18 (presse-papiers de « Copier »), rouge connu hors plan (Phase 75), l'onglet Projet reste inchangé hors ajouts.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — mutants non joués (M-TEINTE, M-CLE-PAGE, M-TOUTVU-FOCUS, M-CLE-REPLI,
M-NETTOIE-STORAGE) ; la garde d'échappement du texte rendu garde son témoin rouge ET son mutant (M-INNER : `createTextNode` remplacé par `insertAdjacentHTML`, W15 rougit, charge de la copie prouvée).
