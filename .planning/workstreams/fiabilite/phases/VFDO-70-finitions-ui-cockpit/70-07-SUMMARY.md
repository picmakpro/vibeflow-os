---
phase: 70-finitions-ui-cockpit
plan: 07
requirements-completed: [UIFN-04]
commits: [9f85885f, f53f8a7b, 7da30363]
patch: P25
---

# 70-07 — visite « Par où commencer » corrigée : résumé

## Livré

- `chrome-visite-etapes.mjs` + section O5 de `test-cockpit-projet.sh` : la visite parcourue étape par étape à 1 440 et 390 px (cible, centrage dans la zone libre non couverte par la carte de visite, texte entier, carte dans la fenêtre, « Passer », repère « n sur N », mots anglais). Rouges avant le patch (`70-07-RED-TRACE.md`), verts après.
- `40-tour.js` (patch **P25**, `assets__ui__40-tour.js.diff`, ligne `PATCH` de `VENDORED.txt` ; V6 et V7 verts) : texte jamais coupé (`clip` ne fait plus que rogner les espaces), « Skip » à chaque étape, carte de visite en colonne à hauteur bornée (le texte défile, les boutons restent), étape de carte = carte sélectionnée, zoomée et centrée dans la plus grande zone libre (au-dessus ou à côté de la carte de visite), étape sur un élément du chrome = contour `--ring` (`.tour-target`) retiré à l'étape suivante et à la fin, carte de visite passée de l'autre côté si elle couvrait la cible.
- `79-vf-fr-dict-b.js` : 4 entrées (« ⋯ › Start here », « The project », « This project », note de repli de l'onglet Projet).

## Pour 70-08 (visite propre à l'onglet Projet)

- Comportement ajouté : une étape de `G.tour` peut porter `cible` (sélecteur CSS d'un élément visible du chrome, `ref` facultatif). Un sélecteur invalide ou sans correspondance est abandonné sans erreur (T-70-11) ; une étape sans `ref` ni `cible` valide est retirée. Une étape `root` sans `cible` reçoit `#context` (le titre de la vue d'ensemble).
- Sur l'onglet Projet (`G.meta.vfTab === 'project'`) : aucune étape « un vrai parcours » n'est ajoutée, et le texte de repli de la première étape ne parle pas de code. Les étapes automatiques de Projet restent celles du moteur (cartes de premier niveau) : le contenu propre est à poser par 70-08.
- Une étape de flux (`flow`) vise désormais la première carte du flux et non plus `root`.

## Points à connaître

- Étapes dont la cible est un bouton du « ⋯ » (≤ 700 px, 70-05) : aucune étape existante ne vise un bouton d'en-tête ; les cibles sont des cartes ou `#context`, visibles à toute largeur. Le seul texte qui nommait un bouton d'en-tête (dernière étape : « depuis Par où commencer en haut ») dit, quand `#tour-btn` n'est pas affiché, « ⋯ › Par où commencer ». Sous 1 600 px le bouton n'est qu'une icône (libellé en infobulle) : le texte nomme son libellé, comme avant.
- Le centrage passe par l'événement `wheel` du viewer (déplacement ; ctrl + molette pour le zoom) : `viewer.html` est interdit à ce plan, `setT` n'est pas exposé. Si le viewer change ce gestionnaire, O5.1 rougit.
- `test-cockpit-responsive.sh` non rejoué (consigne du mandat).
- estimate/actuals : le PLAN ne porte pas de mesure `actuals` rendue par un moteur ; aucun nombre inventé.

## Correctifs ultérieurs (patch P25 mis à jour)

- Rechargement : le fit d'ouverture ne défait plus le centrage d'une première étape qui est une carte (O6.9, O5.6).
- REG-70-01 : centrage borné par le graphe entier, dézoom d'une grande carte, visite qui ne sélectionne plus (le panneau garde la vue d'ensemble) ; O6.10. **À arbitrer** : le centrage de P70-D-02 est borné par « toutes les cartes restent dans la zone libre » (critère de R1) ; une carte excentrée n'est donc pas toujours au milieu.
- « Passer », Échap et la croix rendent la vue d'ensemble ajustée, comme « Terminé » (O6.11) ; le contour de l'étape sur un élément du chrome est un élément à part, indépendant du `className` de la cible (O6.12).
- Preuves : `70-07-RED-TRACE.md`, sections « Suite : … ».
- CI Linux (R20 à 768 px, `#panel` recouvre `#tour`) : la carte de visite se rétrécit plutôt que de passer sous le panneau de détail (O6.13, panneau élargi). Cause non observée sous Linux, déduite : l'émulation `pointer: none` ne la reproduit pas (R20 vert sans pointeur).
- CI Linux, seconde cause (R20 à 768 px, `#context` recouvre `#tour`) : la visite ne s'ouvrait pas seulement sur Code et Projet ; elle s'ouvrait d'elle-même sur Équipe, qui n'a aucune visite conçue. `start()` sans argument (démarrage d'office) ne fait plus rien sur Équipe, le bouton l'ouvre toujours (O6.14).
- CI Linux, R15.4b : la visite d'office, ouverte pendant la mesure, capte la première Échap (bon ordre) ; `INJ_ECHAP` ferme la visite avant l'Échap (section R15 de la suite responsive) ; O6.15 fixe l'ordre visite puis tiroir. `40-tour.js` inchangé.
- Tri de goût de Samuel (P70-D-23, « Tout selon les recos (Recommandé) », AskUserQuestion, session principale Claude Code, 2026-11-04) : zoom lisible sous 701 px (Q6b), services extérieurs allumés (Q7b), texte et infobulle qui disent le bouton tel qu'il s'affiche, « de ce projet » sur Projet (Q9b), bouton désactivé sur Équipe (Q13a). Risque : zoom de 390 px et suite responsive à rejouer.
- Classe « visite / surfaces » (CI Linux de 07e75a54, R3 `#zoom` à 800 px) : `place()` évite toutes les surfaces fixes (O6.17, cinq largeurs, Code et Projet) ; la suite responsive attend la visite d'office avant de mesurer (`chrome-responsive.mjs`).
- Toute largeur de police (CI Linux de 63efb1e1) : passe « police large » de O6.17 (témoin générique) et RESP_POLICE de la suite responsive ; hauteur maximale de la carte de visite sous le bas réel du titre, raccourcissement jusqu'à 120 px, zoom ciblé contrôlé deux fois et borné par le graphe sous 701 px tant que la carte reste lisible. R22 et R3 (390 px) non reproduits ici : à confirmer par la CI Linux.
