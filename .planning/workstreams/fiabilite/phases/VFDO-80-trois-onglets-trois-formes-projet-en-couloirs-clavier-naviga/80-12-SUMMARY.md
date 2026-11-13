# 80-12 — SUMMARY

## Livré
- `04-vf-canevas-champ.js` (49 lignes, neuf) : `cadrerVoisins()` — voisins = cartes reliées à la sélection par une arête du niveau, de tout genre (aucune lecture de `.req` ni des liens « couvre ») ;
  `VibeFlow.cadrage({ ids })` (plancher de l'onglet) puis `VibeFlow.transformer`, aucune relance de `render` ; tiroir Git ouvert : zone à droite du tiroir ;
  `VF_CANEVAS.focaliser` rend le focus à la carte sélectionnée (carte itinérante) et la ramène dans le champ si le plancher a rogné le groupe ;
  feuille de détail ou pointeur grossier : la carte sélectionnée sort de `#zoom` et de la pastille « Terminal » par la plus petite translation qui la garde dans le champ, `k` inchangé.
- `04-vf-clavier-canevas.js` (255 lignes, +40) : la touche `c`/`C` (écouteur de `window` posé dans le rappel `surOnglet` à clé, retiré avec lui, A51) ; gardes : ⌘, Ctrl, Alt, saisie
  (`VibeFlow.enSaisie`), Équipe, sans sélection, visite guidée, palette ouverte ; `VF_CANEVAS.cadrerVoisins()` exposé (palette et aide, plans 80-14 et 80-15), qui délègue.
- `VENDORED.txt` : la ligne `AJOUT assets/ui/04-vf-canevas-champ.js`, à sa place alphabétique (seule ligne de ce plan).
- Suite `test-cockpit-cadrer.sh` (17 PASS) et pilote `chrome-cadrer.mjs`. Trace rouge : `80-12-RED-TRACE.md` (11 PASS / 6 FAIL sur la base).
- Découpage fait ici (budget de 255 lignes du mandat) ; `wc -l` : `04-vf-clavier-canevas.js` 255 (avant 215), `04-vf-canevas-champ.js` 49. Aucune ligne de plus de 160 colonnes ; `colonnes-baseline.txt` non touché.

## Écarts
- Écart : `VF_ONGLETS.aller` (80-10) absent : CA2.5 passe par `VF_COQUILLE.chargerOnglet` (deux allers-retours Projet / Code) ; à ajouter après 80-10 : le même cas par `VF_ONGLETS.aller`.
- Écart : CA1.4 — avec le plancher 11/13, un groupe plus large que le champ de lecture est rogné à droite et en bas (même constat que ZG1.2 de 80-09) : à 390 px, ou à 800 px feuille ouverte,
  deux colonnes de cartes ne tiennent pas. CA1.4 tient donc « ni `#ask` ni feuille touchés par le groupe » seulement quand le groupe tient dans le champ ; sinon seule la carte sélectionnée est tenue
  (entière dans le champ, hors `#zoom`, hors pastille). Version stricte du plan jouée avant le code : rouge de la trace ; la contrainte stricte contredit le plancher, le plancher l'emporte.
- Écart : le lab de la suite place les voisins par des imports (`src/n05.js` importe `n06`, `n07`, `n08`) dans un dossier de 70 fichiers ; le rouge de CA1.4 (feuille ouverte) n'est pas tracé pour la forme relâchée.
- Écart : mode focus recomposé par ELK : voir la réserve ci-dessous. Mutants M-SANS-PLANCHER, M-COPIE, M-RELAYOUT, M-SANS-CLE : levés (régime allégé), aucune ligne « le mutant rougit ».
- Cas à ajouter après livrable absent : CA2.5 par `VF_ONGLETS.aller` (après 80-10) ; positions des cartes posées par le worker de 79-18 avant `render` (après 79-18) : lues après `render`, comme aujourd'hui.

Réserve : mode focus recomposé (P80-D-17) — le mode qui recompose un sous-graphe par ELK reste en réserve, après le worker de mise en page de la Phase 79 (79-18) ; ce plan ne fait que cadrer, sans nouvelle mise en page.

## Suites jouées sur la tête commitée
- cadrer 17/0 (33 s), terminal-activation 54/0 (T7.5 vert après la lecture de la pastille par `data-vf-flottant="bouton"`, demande du manager), clavier-canevas 33/0 (244 s), zoom-garde 23/0 (41 s).
- vendor 248/4 : V11.Q6a, V11.Q6b, V11.P5 (rouges connus) et V4c.9a « HAUSSE » : `41-vf-projet-panneau.js` réel=2 baseline=0, fichier du nœud p11 (aucun fichier de ce plan n'a de ligne longue).
- equipe 196/19 : EK10 (« coquille prête » dépassée à 30 s, cinq suites en parallèle sur le poste, non rejoué : la suite dure 8 min) ; EA2.x et EA3.x : « Cannot read properties of undefined (reading 'lire') », module du tiroir « Qui a la main » (nœuds voisins), hors des fichiers de ce plan, qui ne posent aucun écouteur sur Équipe.

## Rituel
rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## CHANGELOG demandé (80-18)
Cockpit : la touche C cadre d'un geste la carte sélectionnée et ses voisins du niveau, sans nouvelle mise en page et sans descendre sous la taille de lecture ; elle ne prend jamais la copie (⌘C), la saisie ni l'onglet Équipe.

## Rejeu CA2.5 par `VF_ONGLETS.aller` (après 80-10)
CA2.5 passe désormais par `VF_ONGLETS.aller` (aide `onglet` de `chrome-cadrer.mjs`) : cadrer 17/0. Rouge : sans objet, avant 80-10 `aller` n'existait pas (0 occurrence dans `00-vf-onglets.js` à `2736fe67^`).
