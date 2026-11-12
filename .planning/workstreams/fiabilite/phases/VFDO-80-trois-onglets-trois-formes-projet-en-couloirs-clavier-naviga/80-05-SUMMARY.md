---
phase: 80
plan: "05"
status: complete
requirements: [FORM-10, FORM-12]
commits:
  - 5bd5c705 test(80-05) témoins rouges des repères
  - 80e3b8d4 docs(80-05) amendement daté (CN2.1 : 32 px du panneau, zoom déjà à 44)
  - 1d47a9dc feat(80-05) repères de bord (porte aussi les trois lignes 41-vf-projet-* de 80-04 dans VENDORED.txt)
  - 6a455c41 test(80-05) témoins rouges du bloc, de la minicarte, de la ligne d'état
  - 9e60d903 feat(80-05) minicarte et ligne d'état (porte aussi les trois lignes 41-vf-projet-* de 80-04, au même contenu)
  - 7fb284e2 feat(80-05) zone basse, onglets, focus orphelin, terminal (dernier commit de code)
---

# 80-05 — SUMMARY : coin bas-droit, ligne d'état, repères de bord (FORM-10, FORM-12)

## Livré
- `ui/02-vf-reperes.js` (136 lignes) : un `button.vf-repere[data-bord]` par bord du champ de lecture qui a des cartes ENTIÈREMENT hors champ, nom « N cartes hors champ à <bord>. Aller à la plus proche. »,
  dans l'ordre de Tab juste après `#svg` ; clic ou Entrée = `VF_CANEVAS.amenerDansLeChamp` de la carte la plus proche (ni zoom ni sélection) ; place au milieu du bord, poussée à 8 px de `#vf-coin`, `#zoom`,
  `#ask`, pastille et tiroir du terminal ; masqué faute de place, sur la carte sélectionnée ou focalisée, feuille de détail ouverte ; focus orphelin : fruit du geste, voisin suivant puis précédent, carte itinérante, `#stage`.
- `ui/02-vf-coin.js` (130 lignes) : `#vf-coin` dans `#stage` (16 px de la zone libre, 8 px au-dessus de `#ask`), minicarte <= 144 x 96 (cartes, cadre de `freeArea()`, hachure de la part sous le tiroir Git, clic
  et glissement qui recentrent sans changer le zoom), absente sous 1 000 px, au doigt et sous 360 px de hauteur utile ; onglets du téléphone 36 / piste 44 / zone d'appui 44 ; `window.VF_COIN = { rectangle() }`.
- `ui/02-vf-ligne-etat.js` (92 lignes) : branche entière (ellipse 10 + … + 8 en JS, nom complet en title et étiquette), « Direct » / « Direct coupé » (seule rangée `role=status`), « Mis à jour à HH:MM » ; aucune requête.
- `VENDORED.txt` : trois lignes `AJOUT assets/ui/02-vf-*.js`. `test-cockpit-coin.sh` (195 lignes) + `chrome-coin.mjs` (288) : CN1, CN2, CN3, 5 mutants. `80-05-RED-TRACE.md`.

## Vérifications
- `test-cockpit-coin.sh` : 33 PASS / 0 FAIL. Rouge sur la base : voir RED-TRACE (CN1 : 2/4, CN2 : 2/12, CN3 : 5/28 sur la suite entière).
- Non-régression rejouées : accessibilite 35/0, clavier-canevas 32/0, vendor 137/0, moteur-carte 73/0, equipe 215/0, git-tiroir 194/0 (isolé), responsive 378/0 (isolé ; R15.5 rouge dans un rejeu sous charge, vert isolé), terminal-tiroir 138/0 (isolé ; T21.1 et T21.4 rouges dans deux rejeux sous la charge des suites voisines, D2.6 de git-tiroir idem, verts isolés et sur une copie sans les trois modules).
- Gabarit : trois modules, suite et pilote <= 299 lignes, aucune ligne > 160 points de code ; `css-jetons.mjs` vert ; aucun `fetch(`, `requestAnimationFrame`, `.animate(`.

## Écarts au plan
- Amendement daté 80e3b8d4 : bloc à 32 px du panneau (16 de la zone libre), zoom déjà à 44 px (rien à ajouter).
- Défaut vu à la capture claire (cadre de la minicarte plein) : corrigé, mesure CN2.3 ajoutée (trace dans RED-TRACE).
- CN1.2 renforcée (carte la plus proche entièrement dans le champ) ; mutants M-ORPHELIN et M-ONGLETS ajoutés ; `CN_SOLO=<mode>[:sections]` pour une mesure brute ou les captures (`CN_SOLO=shots CN_SHOTS=<dossier>`).
- La visite guidée (`39-vf-tour-placement.js`, `obstacles()`) ne connaît pas `#vf-coin` : sa carte peut le recouvrir ; hors `files_modified`, à traiter par la jointure.

## Pour la jointure et les plans suivants
- Mutants : copie maison (`mutant()` : scripts + moteur dans `$WORK`) ; à passer à `cockpit_module_copie`. Idiome A51 non appliqué (les trois fichiers s'initialisent par `VF_COQUILLE.surOnglet` s'il existe, sinon `ready`).
- `VF_COIN.rectangle()` rend un DOMRect (ou null s'il n'est pas affiché). `#vf-coin-etat` est l'emplacement de la ligne d'état. Le direct se lit sur `#vf-lock.off` et `window.__vfLive.connected` ; « Mis à jour » suit `vf-who`
  et le compteur de patchs, à remplacer par `VF_ETAT.lire('connexion')` / l'événement `graphe` de la 79.
- Ligne de CHANGELOG pour 80-18 : « cockpit : minicarte, ligne d'état (branche, direct, heure) et repères « N cartes par là » en bas à droite de la carte ».
