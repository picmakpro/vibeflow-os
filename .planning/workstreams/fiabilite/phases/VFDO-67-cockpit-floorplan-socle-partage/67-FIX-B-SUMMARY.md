# 67-FIX-B — SUMMARY (correction ciblée B : interface, responsive CKPT-12, suivi documentaire)

Nœud `fix-67-b`, Phase 67, tour de correction 1 sur 3 · mandat `vf-dev-manager-v2-cockpit` · arbre `v2-cockpit`, branche `feat/v2-cockpit`, de `7929d2a8` à `45dfb75f` (+ commit de documentation).
Arbitrages : lot B validé (arbitrage Samuel, AskUserQuestion session principale, 2026-11-01) ; CKPT-12 = demande de Samuel (message session principale, 2026-11-01) « au moins pouvoir avoir la fenêtre ajustable » ; CKPT-09 reformulé sur la réponse E1 de Samuel (`67-CONTEXT.md` P67-D-20).
Aucun cycle cadrage/plan : uniquement les écarts E-1 à E-7 constatés au navigateur par le head (recette déléguée, `eb2e786d`).

## Corrigé

| écart | commit | témoin (module d'avant `7929d2a8` → après) |
|---|---|---|
| E-1 en-tête cassé (grille `auto minmax(0,1fr) auto` de 80-vf-fr.js : recherche à 0 px, nom non tronqué) | a253d713, 45dfb75f (badge) | test-cockpit-responsive.sh R1/R2 : 5 PASS / 31 FAIL → 41 PASS / 0 FAIL ; recherche 24 px → 320-400 px |
| E-2 barre de question tronquée sur deux lignes, zoom au milieu | a253d713 | R1/R2 : invite 632 px > 170 → 250 px sur 269 disponibles à 1 024 px ; barre 102 → 54 px de haut ; R3 (800, 390 px) |
| E-3 logo = un tiret orange (`filter: invert(1)` du viewer sur un logo déjà sombre) | a253d713 | R1 : `logoFiltre` `invert(1)` → `none`, 22x22 |
| E-4 lab sans STATE.md | a253d713 | R5.1-R5.3 : plus de « ? », de « () », de « Maintenant · / Phase — » |
| E-5 « Voir la dernière commande » : « Indisponible. » | 45dfb75f | W11, W12 : 4 FAIL → 0 |
| E-6 reconnexion sans recul | 45dfb75f | test-cockpit-reconnexion.sh N2.1 : 8 requêtes entre 5 s et 9 s → 0 ; message et « Réessayer » |
| E-7 titre, export, journal, « Thinking… », DAG des missions, résumé de carte | a253d713, 45dfb75f | R6.1-R6.3 ; S9 (3 FAIL → 0) ; W12 ; D6 (1 FAIL → 0) |

## Cause de E-5

Deux causes cumulées dans `vf-cockpit-who.mjs`. (1) La dernière ligne `user`/`assistant` d'une session très active est presque toujours un résultat d'outil
(message `user` dont le contenu est un `tool_result`, sans texte) : `lastText()` rendait `''`, falsy côté page, d'où « Indisponible. » (un sous-agent finit plus souvent sur
un message d'assistant avec du texte). (2) La lecture ne portait que sur les 256 derniers Kio : quand la dernière ligne les dépasse (gros résultat d'outil d'une session
principale), aucune ligne n'était complète et la session disparaissait même du badge « au travail ». Correction : recherche depuis la fin, fenêtres de 256 Kio, 2 Mio, 8 Mio,
jusqu'à la dernière action de l'assistant (texte ou appel d'outil, commande ou description) ; sans action lisible, erreur nommée `sans-action` et libellé honnête. La commande
n'entre toujours ni dans le flux, ni dans les fichiers, ni dans l'export (P67-D-14 ; S5-S7 inchangés et verts).

## Mesures de mise en page (CKPT-12)

Lab de nom court et lab de nom de 60 caractères, onglets Code et Projet, badge « 1 au travail » (verrou au nom long + nœud de DAG) : aucune superposition, aucun rognage.

| largeur | recherche | barre de question | invite (besoin/disponible) | carte (zone libre) |
|---|---|---|---|---|
| 1 024 | 320 px | 584 x 54 | 250/269 | 65..567 / 0..648 |
| 1 280 | 400 px | 568 x 54 | 250/253 | 177..711 / 0..904 |
| 1 440 | 400 px | 700 x 54 | 250/385 | 207..841 / 0..1064 |
| 1 920 | 400 px | 700 x 54 | 250/385 | 359..1169 / 0..1544 |
| 1 920 → 1 024 à chaud | 320 px | 584 x 54 | 250/269 | 89..543 / 0..648 (recadrée) |

## Écarts et décisions à connaître

- **Fichier hors périmètre listé, touché** : `README.md` et `README.fr.md` (compteur de suites 139 → 141, `check-version-sync`), prévu par le mandat.
- **Patchs amont P20 (serve.mjs, nom du fichier exporté) et P21 (viewer.html, flux coupé remis à la page hôte)** : diffs régénérés depuis un amont reconstruit (hash vérifié contre le manifeste), `VENDORED.txt` à jour, `synchro.sh verifier` rc 0.
- **Règle de grille retirée de `80-vf-fr.js`** (elle écrasait la recherche) : la mise en page de l'en-tête est désormais le seul travail de `01-vf-responsive.js`.
- **Invite de la barre de question** : « Posez une question sur ce projet… » (le nom du projet est déjà dans l'en-tête et pouvait faire 60 caractères).
- **Boutons d'en-tête en icône seule sous 1 600 px** (infobulle conservée) : seuil mesuré, pas arbitraire (les libellés français + badge + recherche de 200 px ne tiennent pas en dessous avec un nom de projet lisible).
- **Zoom à 800 px** : reste à gauche du panneau de détails (gabarit étroit du moteur, 701-999 px) ; à 390 px il est dans l'en-tête et le fil d'Ariane cède sa place. Non modifié sur 701-999 px : lisible, sans superposition (R3).
- **Fin du sondage** : 5 minutes (le mandat disait « puis arrêt » sans durée) ; valeur lisible et modifiable par `window.__vfLive.reco`.
- **Flake constaté** : `test-cockpit-chaine-xss.sh` (C0.3, C4.2) a rougi une fois pendant un rejeu où deux autres jeux de Chrome headless tournaient en parallèle ; vert seul, vert au rejeu final.

## Restes

Panneau Santé et couverture de l'onglet Code en anglais (CKPT-09 reformulé, BACKLOG : choix de la langue) ; la mise en page sous 1 024 px n'est mesurée qu'à 800 et 390 px ; le sélecteur de modèle laisse 3 px de marge à l'invite à 1 280 px.

## Rejeu final

Voir le message de retour du mandat (SHA final, suites, `synchro.sh verifier`, `check-version-sync`).
