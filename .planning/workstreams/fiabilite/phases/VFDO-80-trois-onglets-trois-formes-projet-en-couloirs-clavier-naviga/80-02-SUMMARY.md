---
phase: 80
plan: "02"
subsystem: cockpit-surcouches
requirements-completed: [FORM-02]
key-files:
  created:
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vf-surcouches.js
    - plugin/cockpit/scripts/tests/test-cockpit-surcouches.sh
    - plugin/cockpit/scripts/tests/chrome-surcouches.mjs
    - .planning/workstreams/fiabilite/phases/VFDO-80-trois-onglets-trois-formes-projet-en-couloirs-clavier-naviga/80-02-RED-TRACE.md
  modified:
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/02-vf-telephone.js
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/73-vf-tiroir-travail.js
    - plugin/cockpit/skills/cockpit-moteur/assets/ui/77-vf-git-tiroir.js
    - plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
duration: non mesurée
---

# 80-02 — pile unique de surcouches

## Livré
- `window.VF_SURCOUCHES = { ouvrir, fermer, dessus, ouverte, couverte }` (gelée, garde d'unicité), module de 126 lignes, aucune ligne > 160 points de code.
  Écouteur de touches en capture sur `window` posé une fois à l'évaluation ; seule la fonction d'accroches lit le moteur et passe par
  `VF_COQUILLE.surOnglet` quand elle existe (sinon appelée tout de suite).
- Modales (palette, export, toute entrée `modale: true`) : piège Tab/Maj+Tab, `inert` sur les frères de la boîte au niveau de `body` (liste tenue à part,
  jamais un `[inert]` levé en bloc), focus rendu à l'ouvreur ; l'`inert` est levé AVANT que le moteur ferme (Échap, fond, croix, choix d'un résultat).
- Échap : une surcouche fermée par la pile consomme l'appui (`preventDefault` puis `stopPropagation`) ; sans surcouche, terminal focalisé, menus, parcours,
  visite, bulles : l'appui passe intact. Tiroirs non modaux : cran « corps/canevas » seulement ; leurs écouteurs fins restent dans leurs fichiers.
- Panneau fermé (> 700 px) : `visibility: hidden` après la transition, levé avant l'ouverture ; focus resté dedans -> `#btn-panel`, sinon carte itinérante, sinon `#stage`.
- Retrait 4 : les trois listes `#palette.open, #flowmenu.open…` remplacées par `VF_SURCOUCHES.couverte(<élément>)` ; tiroirs Git et « Au travail » inscrits/retirés.
- Lignes longues retirées (> 160 colonnes) : `02-vf-telephone.js` 56 -> 55 (-1), `73-vf-tiroir-travail.js` 12 -> 12 (0), `77-vf-git-tiroir.js` 39 -> 39 (0).
  Seule la ligne de 02 baisse ; la jointure abaisse la baseline de 1 pour 02.

## Commits
`b17da13e` test (rouge) · `2afcd1db` test (mise au point) · `ef0e9ec9` feat (pile + VENDORED) · `0dd24ac6` refactor (3 listes) · amendement du plan · fix (inert levé avant la fermeture) · fix (Entrée/clic sur un résultat).

## Preuves
- `test-cockpit-surcouches.sh` : 26 PASS / 0 FAIL, SU6.1 et M-PERSISTANT en `⏳ ATTENTE` (coquille de la 79). Rouge sur la base : 6 PASS / 20 FAIL (RED-TRACE).
- Mutants (copie complète du lab dans `$WORK`, jamais `cockpit_module_copie`) : M-INERT-TOUT -> SU2.3 ; M-PIEGE -> SU2.1 ; M-PALETTE -> SU1.1 ; M-ECHAP-VIDE -> SU4.5 ;
  M-SANS-PREVENT -> SU4.4 ; M-UNICITE -> SU1.3 (+ mutant sans effet refusé : lignes changées module = page).
- Non-régression : test-cockpit-vendor, moteur-carte, terminal-tiroir verts ; git-tiroir, responsive, equipe : voir « Écarts ».

## Non-régression (rejeux isolés, comparés à une copie `git archive` de 680364f1)
- test-cockpit-equipe : EK15.6 vert sur la base, rouge avec la première pile (le rescue du focus du panneau pré-empte « Au travail ») ; corrigé (le rescue
  ne joue pas quand un tiroir inscrit porte le panneau) : 215 PASS / 0 FAIL. (La copie archive de la base montre 4 rouges EA2.11/EA2.16/EA3.5/EA3.9 : témoins « code d'avant <sha> » qui exigent l'historique git, artefact de l'archive.)
- test-cockpit-git-tiroir : 194 PASS / 0 FAIL (base 194 / 0) après reciblage du mutant M-ECHAP-390 sur `00-vf-surcouches.js` (commit dédié, Gate-Touche). Les D8.* rouges du premier rejeu étaient des aléas de charge.
- test-cockpit-responsive : 378 PASS / 0 FAIL (base 378 / 0) après `panneau: textContent` (l.129, commit dédié, aucune assertion retirée) ; R5.2 reste vert avec le texte caché compté. R15c.2 : rouge dans deux rejeux complets sous charge, vert isolé trois fois (`true|true|true|true`), aléa de charge.
- moteur-carte, terminal-tiroir, vendor : verts.

## Points ouverts
- SU6.1, M-PERSISTANT, idiome A51, `cockpit_module_copie`, baisse de `colonnes-baseline.txt` (02 : -1 ligne longue) : jointure.
- VENDORED.txt : la ligne `AJOUT assets/ui/04-vf-clavier-canevas.js` de 80-01 (non commitée) est partie dans mon commit par pathspec.
- Captures : surcouche-export-terminal-derriere.png, surcouche-palette-terminal-derriere.png (scratchpad de 80-02, dossier png).
